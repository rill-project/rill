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

  @scribble tag: :message_store

  @impl Rill.MessageStore.Database
  def get(%Session{} = session, stream_name, opts)
      when is_binary(stream_name) and is_list(opts) do
    Log.trace tag: :get do
      "Getting (Stream Name: #{stream_name})"
    end

    messages = server_call(session, {:get, stream_name, opts})

    Log.debug tag: :get do
      count = length(messages)
      position = Keyword.get(opts, :position)
      batch_size = Keyword.get(opts, :batch_size)

      "Finished Getting Messages (Stream Name: #{stream_name}, Count: #{count}, Position: #{
        inspect(position)
      }, Batch Size: #{inspect(batch_size)})"
    end

    Log.info tag: :get do
      "Get Completed (Stream Name: #{stream_name})"
    end

    messages
  end

  @impl Rill.MessageStore.Database
  def get_last(%Session{} = session, stream_name)
      when is_binary(stream_name) do
    Log.trace tags: [:get, :get_last] do
      "Getting Last (Stream Name: #{stream_name})"
    end

    last_message = server_call(session, {:get_last, stream_name})

    Log.debug tags: [:get, :get_last, :data] do
      inspect(last_message, pretty: true)
    end

    Log.info tags: [:get, :get_last] do
      "Get Last Completed (Stream Name: #{stream_name})"
    end

    last_message
  end

  @impl Rill.MessageStore.Database
  def put(%Session{} = session, %Write{} = msg, stream_name, opts)
      when is_binary(stream_name) and is_list(opts) do
    Log.trace tag: :put do
      expected_version =
        opts
        |> Keyword.get(:expected_version)
        |> ExpectedVersion.canonize()

      "Putting (Stream Name: #{stream_name}, Expected Version: #{
        inspect(expected_version)
      })"
    end

    Log.debug tags: [:put, :data] do
      inspect(msg, pretty: true)
    end

    position = server_call(session, {:put, msg, stream_name, opts})

    Log.info tag: :put do
      "Put Completed (Stream Name: #{stream_name}, Position: #{position})"
    end

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
