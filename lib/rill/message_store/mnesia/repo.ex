defmodule Rill.MessageStore.Mnesia.Repo do
  @moduledoc false

  alias :mnesia, as: Mnesia
  alias Rill.MessageStore.StreamName
  alias Rill.MessageStore.ExpectedVersion.Error, as: ExpectedVersionError
  alias Rill.MessageStore.Mnesia.TableName
  require Ex2ms

  @type namespace :: atom()
  @type read_message :: list()
  @type write_message :: list()
  @type read_messages :: {[read_message()], term()} | term()

  @message_attrs [
    :global_position,
    # category, id, global, local
    :stream_all,
    # category, id, local
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

  def create(ns) do
    with {:atomic, _} <-
           Mnesia.create_table(
             TableName.table(ns),
             attributes: @message_attrs,
             index: [:id, :stream_all, :stream_local],
             type: :ordered_set
           ),
         {:atomic, _} <-
           Mnesia.create_table(
             TableName.position(ns),
             attributes: [:stream, :position]
           ),
         {:atomic, _} <-
           Mnesia.create_table(
             TableName.global(ns),
             attributes: [:key, :value]
           ),
         {:atomic, _} <-
           Mnesia.transaction(fn ->
             :ok =
               Mnesia.write({
                 TableName.global(ns),
                 :global_position,
                 0
               })
           end) do
      :ok
    else
      error -> error
    end
  end

  def delete(ns) do
    Mnesia.delete_table(TableName.table(ns))
    Mnesia.delete_table(TableName.position(ns))
    Mnesia.delete_table(TableName.global(ns))
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
      Mnesia.write_lock_table(TableName.table(ns))
      Mnesia.write_lock_table(TableName.position(ns))
      Mnesia.write_lock_table(TableName.global(ns))
      {:atomic, version} = stream_version(ns, stream_name)
      {:atomic, global} = new_global_position(ns)
      {:atomic, local} = new_local_position(ns, stream_name)

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
              TableName.table(ns),
              global,
              {stream_category, stream_id, global, local},
              {stream_category, stream_id, local},
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
      target = to_stream(stream_name)

      case wget({TableName.position(ns), target}) do
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
        {_table, _global, {stream_category, _p_stream_id, global, _p_local},
         _stream_local, _id, _stream_name, _stream_category, _stream_id, _type,
         _local, _data, _metadata, _time} = record
        when stream_category == ^category_name and global >= ^global_pos ->
          record
      end

    Mnesia.transaction(fn ->
      table = TableName.table(ns)

      case Mnesia.select(table, spec, batch_size, :read) do
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
        {_table, _global, {stream_category, stream_id, _p_global, local},
         _stream_local, _id, _stream_name, _stream_category, _stream_id, _type,
         _local, _data, _metadata, _time} = record
        when stream_category == ^category and stream_id == ^id and
               local >= ^local_pos ->
          record
      end

    Mnesia.transaction(fn ->
      table = TableName.table(ns)

      case Mnesia.select(table, spec, batch_size, :read) do
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
      target = to_stream(stream_name)

      records =
        case get({TableName.position(ns), target}) do
          nil ->
            []

          {_, _, pos} ->
            stream_local = {category, id, pos}

            Mnesia.index_read(
              TableName.table(ns),
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
      target = to_stream(stream_name)

      current_pos =
        case wget({TableName.position(ns), target}) do
          nil -> -1
          {_, _, pos} -> pos
        end

      new_pos = current_pos + 1
      :ok = Mnesia.write({TableName.position(ns), target, new_pos})
      new_pos
    end)
  end

  defp new_global_position(ns) do
    Mnesia.transaction(fn ->
      global = TableName.global(ns)
      {_, _, current_pos} = wget({global, :global_position})

      new_pos = current_pos + 1
      :ok = Mnesia.write({global, :global_position, new_pos})
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

  defp to_stream(stream_name) do
    id = StreamName.get_id(stream_name)
    category = StreamName.get_category(stream_name)
    {category, id}
  end
end
