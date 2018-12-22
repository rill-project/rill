defmodule Rill.MessageStore.Mnesia.Database do
  defmodule Defaults do
    @spec position() :: 0
    def position, do: 0
    @spec batch_size() :: 1000
    def batch_size, do: 1000
  end

  @behaviour Rill.MessageStore.Database

  use Rill.Kernel
  alias Rill.MessageStore.Mnesia.Repo
  alias Rill.Session
  alias Rill.MessageStore.StreamName
  alias Rill.MessageStore.MessageData.Write
  alias Rill.MessageStore.MessageData.Read
  alias Rill.MessageStore.Mnesia.Database.Serialize
  alias Rill.MessageStore.Mnesia.Database.Deserialize
  alias Rill.Identifier.UUID.Random, as: Identifier
  alias Rill.MessageStore.ExpectedVersion
  alias Rill.Messaging.Message.Transform

  @type row :: tuple()
  @type row_map :: %{
          id: String.t(),
          stream_name: StreamName.t(),
          type: String.t(),
          position: non_neg_integer(),
          global_position: pos_integer(),
          data: map(),
          metadata: map(),
          time: String.t()
        }
  @type get_messages_fun ::
          (Repo.namespace(), StreamName.t(), non_neg_integer(), pos_integer() ->
             Repo.read_messages())

  @impl Rill.MessageStore.Database
  def get(%Session{} = session, stream_name, opts \\ [])
      when is_binary(stream_name) and is_list(opts) do
    Log.trace(fn ->
      {"Getting (Stream Name: #{stream_name})", tags: [:get]}
    end)

    namespace = Session.get_config(session, :namespace)
    position = opts[:position] || Defaults.position()
    batch_size = opts[:batch_size] || Defaults.batch_size()

    messages =
      namespace
      |> mnesia_get(stream_name, position, batch_size)
      |> convert()

    Log.debug(fn ->
      count = length(messages)

      {"Finished Getting Messages (Stream Name: #{stream_name}, Count: #{count}, Position: #{
         inspect(position)
       }, Batch Size: #{inspect(batch_size)})", tags: [:get]}
    end)

    Log.info(fn ->
      {"Get Completed (Stream Name: #{stream_name})", tags: [:get]}
    end)

    messages
  end

  @impl Rill.MessageStore.Database
  def get_last(%Session{} = session, stream_name)
      when is_binary(stream_name) do
    Log.trace(fn ->
      {"Getting Last (Stream Name: #{stream_name})", tags: [:get, :get_last]}
    end)

    namespace = Session.get_config(session, :namespace)

    last_message =
      namespace
      |> mnesia_get_last(stream_name)
      |> convert_row()

    Log.debug(fn ->
      {inspect(last_message, pretty: true), tags: [:get, :get_last, :data]}
    end)

    Log.info(fn ->
      {"Get Last Completed (Stream Name: #{stream_name})",
       tags: [:get, :get_last]}
    end)

    last_message
  end

  @impl Rill.MessageStore.Database
  def put(%Session{} = session, %Write{} = msg, stream_name, opts \\ [])
      when is_binary(stream_name) and is_list(opts) do
    namespace = Session.get_config(session, :namespace)
    identifier_get = Keyword.get(opts, :identifier_get) || (&Identifier.get/0)

    expected_version =
      opts
      |> Keyword.get(:expected_version)
      |> ExpectedVersion.canonize()

    Log.trace(fn ->
      {"Putting (Stream Name: #{stream_name}, Expected Version: #{
         inspect(expected_version)
       })", tags: [:put]}
    end)

    Log.debug(fn -> {inspect(msg, pretty: true), tags: [:put, :data]} end)

    %{id: id, type: type, data: data, metadata: metadata} = msg
    id = id || identifier_get.()
    data = Serialize.data(data)
    metadata = Serialize.metadata(metadata)

    params = [id, stream_name, type, data, metadata, expected_version]

    position =
      namespace
      |> mnesia_put(params)
      |> convert_position()

    Log.info(fn ->
      {"Put Completed (Stream Name: #{stream_name}, Position: #{position})",
       tags: [:put]}
    end)

    position
  end

  @spec mnesia_get(
          ns :: Repo.namespace(),
          stream_name :: StreamName.t(),
          position :: non_neg_integer(),
          batch_size :: pos_integer()
        ) :: Repo.read_messages()
  def mnesia_get(ns, stream_name, position, batch_size)
      when is_binary(stream_name) do
    {:atomic, result} =
      if StreamName.category?(stream_name) do
        Repo.get_category_messages(ns, stream_name, position, batch_size)
      else
        Repo.get_stream_messages(ns, stream_name, position, batch_size)
      end

    result
  end

  @spec mnesia_get_last(ns :: Repo.namespace(), stream_name :: StreamName.t()) ::
          Repo.read_message()
  def mnesia_get_last(ns, stream_name) when is_binary(stream_name) do
    {:atomic, result} = Repo.get_last_message(ns, stream_name)
    result
  end

  @spec mnesia_put(ns :: Repo.namespace(), msg :: Repo.write_message()) ::
          non_neg_integer()
  def mnesia_put(ns, msg) do
    {:atomic, position} = Repo.write_message(ns, msg)
    position
  end

  @spec convert(rows :: {[row()], term()} | term()) :: [row_map()]
  def convert({rows, _cont}) do
    Enum.map(rows, &convert_row/1)
  end

  def convert(_), do: []

  @spec convert_position(rows :: nil | non_neg_integer()) :: non_neg_integer()
  def convert_position(nil), do: nil
  def convert_position(position), do: position

  @spec convert_row(row :: nil | row()) :: row_map()
  def convert_row(nil), do: nil

  def convert_row(row) do
    [id, stream_name, type, position, global_position, data, metadata, time] =
      row

    data = Deserialize.data(data)
    metadata = Deserialize.metadata(metadata)

    record = %{
      id: id,
      stream_name: stream_name,
      type: type,
      position: position,
      global_position: global_position,
      data: data,
      metadata: metadata,
      time: time
    }

    record
    |> Transform.read()
    |> Read.build()
  end
end
