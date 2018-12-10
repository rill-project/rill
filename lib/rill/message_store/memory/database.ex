defmodule Rill.MessageStore.Memory.Database do
  defmodule Defaults do
    @spec position() :: 0
    def position, do: 0
    @spec batch_size() :: 100
    def batch_size, do: 100
  end

  @behaviour Rill.MessageStore.Database

  use Rill.Kernel
  alias Rill.Session
  alias Rill.MessageStore.MessageData.Write
  alias Rill.MessageStore.ExpectedVersion

  @impl Rill.MessageStore.Database
  def get(%Session{} = session, stream_name, opts)
      when is_binary(stream_name) and is_list(opts) do
    Log.trace(fn ->
      {"Getting (Stream Name: #{stream_name})", tags: [:get]}
    end)

    messages = server_call(session, {:get, stream_name, opts})

    Log.debug(fn ->
      count = length(messages)
      position = Keyword.get(opts, :position)
      batch_size = Keyword.get(opts, :batch_size)

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

    last_message = server_call(session, {:get_last, stream_name})

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
  def put(%Session{} = session, %Write{} = msg, stream_name, opts)
      when is_binary(stream_name) and is_list(opts) do
    Log.trace(fn ->
      expected_version =
        opts
        |> Keyword.get(:expected_version)
        |> ExpectedVersion.canonize()

      {"Putting (Stream Name: #{stream_name}, Expected Version: #{
         inspect(expected_version)
       })", tags: [:put]}
    end)

    Log.debug(fn -> {inspect(msg, pretty: true), tags: [:put, :data]} end)
    position = server_call(session, {:put, msg, stream_name, opts})

    Log.info(fn ->
      {"Put Completed (Stream Name: #{stream_name}, Position: #{position})",
       tags: [:put]}
    end)

    position
  end

  # just a wrapper for calling genserver
  defp server_call(%Session{} = session, params) when is_tuple(params) do
    pid = Session.get_config(session, :pid)

    with {:ok, result} <- GenServer.call(pid, params) do
      result
    else
      {:error, :concurrency_issue} ->
        raise(Rill.MessageStore.ExpectedVersion.Error)
    end
  end
end
