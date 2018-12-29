defmodule Rill.MessageStore.Mnesia.Repo do
  @moduledoc false

  alias :mnesia, as: Mnesia
  alias Rill.MessageStore.StreamName
  alias Rill.MessageStore.ExpectedVersion.Error, as: ExpectedVersionError
  require Ex2ms

  @table Rill.Message
  @table_position Rill.Message.Position
  @table_global Rill.Message.Global

  @type namespace :: String.t()
  @type read_message :: list()
  @type write_message :: list()
  @type read_messages :: {[read_message()], term()} | term()

  @message_attrs [
    :namespace_global,
    :namespace,
    :global_position,
    # namespace, category, id, global, local
    :stream_all,
    # namespace, category, id, local
    :stream_local,
    :id,
    :stream_name,
    :stream_category,
    :stream_id,
    :type,
    :position,
    :data,
    :metadata,
    :time
  ]
  # + 1 erlang is 1-based, + 1 first term is table name
  @message_stream_local_idx Enum.find_index(@message_attrs, fn attr ->
                              attr == :stream_local
                            end) + 2

  defdelegate start, to: Mnesia
  defdelegate transaction(fun, retries), to: Mnesia

  def create do
    with {:atomic, _} <-
           Mnesia.create_table(
             @table,
             attributes: @message_attrs,
             index: [:id, :stream_all, :stream_local],
             type: :ordered_set
           ),
         {:atomic, _} <-
           Mnesia.create_table(
             @table_position,
             # stream: {namespace, category, id}
             attributes: [:stream, :position]
           ),
         {:atomic, _} <-
           Mnesia.create_table(
             @table_global,
             attributes: [:namespace, :value]
           ) do
      :ok
    else
      error -> error
    end
  end

  def delete do
    Mnesia.delete_table(@table)
    Mnesia.delete_table(@table_position)
    Mnesia.delete_table(@table_global)
    :ok
  end

  def write_message(ns, [
        id,
        stream_name,
        type,
        data,
        metadata,
        expected_version
      ]) do
    Mnesia.transaction(fn ->
      Mnesia.write_lock_table(@table)
      Mnesia.write_lock_table(@table_position)
      Mnesia.write_lock_table(@table_global)
      {:atomic, version} = stream_version(ns, stream_name)
      {:atomic, global} = new_global_position(ns)
      {:atomic, local} = new_local_position(ns, stream_name) |> IO.inspect()

      case same_version?(version, expected_version) do
        false ->
          Mnesia.abort(%ExpectedVersionError{
            message: "#{expected_version} != #{version}"
          })

        true ->
          stream_category = StreamName.get_category(stream_name)
          stream_id = StreamName.get_id(stream_name)

          :ok =
            Mnesia.write({
              @table,
              {ns, global},
              ns,
              global,
              {ns, stream_category, stream_id, global, local},
              {ns, stream_category, stream_id, local},
              id,
              stream_name,
              stream_category,
              stream_id,
              to_string(type),
              local,
              data,
              metadata,
              NaiveDateTime.utc_now()
            })

          local
      end
    end)
  end

  def write_messages(ns, messages) do
    Mnesia.transaction(fn ->
      Enum.reduce(messages, nil, fn message, _ ->
        {:atomic, version} = write_message(ns, message)
        version
      end)
    end)
  end

  def stream_version(ns, stream_name) do
    Mnesia.transaction(fn ->
      target = to_stream(ns, stream_name)

      case wget({@table_position, target}) do
        {_, _, current_pos} -> current_pos
        nil -> nil
      end
    end)
  end

  def get_category_messages(_ns, _stream_name, _global_pos, 0),
    do: {[], :"$end_of_table"}

  def get_category_messages(ns, stream_name, global_pos, batch_size) do
    unless StreamName.category?(stream_name) do
      raise StreamName.Error, message: "Stream name not a category"
    end

    category_name = StreamName.get_category(stream_name)

    spec =
      Ex2ms.fun do
        {_table, _ns_global, _ns, _global,
         {ns, stream_category, _p_stream_id, global, _p_local}, _stream_local,
         _id, _stream_name, _stream_category, _stream_id, _type, _local, _data,
         _metadata, _time} = record
        when ns == ^ns and stream_category == ^category_name and
               global >= ^global_pos ->
          record
      end

    Mnesia.transaction(fn ->
      case Mnesia.select(@table, spec, batch_size, :read) do
        {records, cont} -> {Enum.map(records, &decode/1), cont}
        :"$end_of_table" -> {[], :"$end_of_table"}
        error -> error
      end
    end)
  end

  def get_stream_messages(_ns, _stream_name, _local_pos, 0),
    do: {[], :"$end_of_table"}

  def get_stream_messages(ns, stream_name, local_pos, batch_size) do
    if StreamName.category?(stream_name) do
      raise StreamName.Error, message: "Stream name is a category"
    end

    id = StreamName.get_id(stream_name)
    category = StreamName.get_category(stream_name)

    spec =
      Ex2ms.fun do
        {_table, _ns_global, _ns, _global,
         {ns, stream_category, stream_id, _p_global, local}, _stream_local, _id,
         _stream_name, _stream_category, _stream_id, _type, _local, _data,
         _metadata, _time} = record
        when ns == ^ns and stream_category == ^category and stream_id == ^id and
               local >= ^local_pos ->
          record
      end

    Mnesia.transaction(fn ->
      case Mnesia.select(@table, spec, batch_size, :read) do
        {records, cont} -> {Enum.map(records, &decode/1), cont}
        :"$end_of_table" -> {[], :"$end_of_table"}
        error -> error
      end
    end)
  end

  def get_last_message(ns, stream_name) do
    if StreamName.category?(stream_name) do
      raise StreamName.Error, message: "Stream name is a category"
    end

    Mnesia.transaction(fn ->
      id = StreamName.get_id(stream_name)
      category = StreamName.get_category(stream_name)
      target = to_stream(ns, stream_name)

      records =
        case get({@table_position, target}) do
          nil ->
            []

          {_, _, pos} ->
            stream_local = {ns, category, id, pos}

            Mnesia.index_read(
              @table,
              stream_local,
              @message_stream_local_idx
            )
        end

      records
      |> List.first()
      |> decode()
    end)
  end

  defp same_version?(_version, nil), do: true
  defp same_version?(nil, -1), do: true

  defp same_version?(version, expected) when is_integer(version) do
    version == expected
  end

  defp new_local_position(ns, stream_name) do
    Mnesia.transaction(fn ->
      target = to_stream(ns, stream_name)

      current_pos =
        case wget({@table_position, target}) do
          nil -> -1
          {_, _, pos} -> pos
        end

      new_pos = current_pos + 1
      :ok = Mnesia.write({@table_position, target, new_pos})
      new_pos
    end)
  end

  defp new_global_position(ns) do
    Mnesia.transaction(fn ->
      {_, _, current_pos} = wget({@table_global, ns}, {nil, nil, 0})

      new_pos = current_pos + 1
      :ok = Mnesia.write({@table_global, ns, new_pos})
      new_pos
    end)
  end

  defp wget(record, default \\ nil), do: get(record, default, :write)

  defp get({tab, key}, default \\ nil, lock \\ :read) do
    case Mnesia.read(tab, key, lock) do
      [] -> default
      [record] -> record
    end
  end

  defp decode(nil), do: nil

  defp decode({
         _table,
         _ns_global,
         _ns,
         global_position,
         _stream_all,
         _stream_local,
         id,
         stream_name,
         _stream_category,
         _stream_id,
         type,
         position,
         data,
         metadata,
         time
       }) do
    [id, stream_name, type, position, global_position, data, metadata, time]
  end

  defp to_stream(ns, stream_name) do
    id = StreamName.get_id(stream_name)
    category = StreamName.get_category(stream_name)
    {ns, category, id}
  end
end
