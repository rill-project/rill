defmodule Rill.MessageStore.Memory.Database do
  defmodule Defaults do
    @spec position() :: 0
    def position, do: 0
    @spec batch_size() :: 100
    def batch_size, do: 100
  end

  @behaviour Rill.MessageStore.Database

  alias Rill.Session
  alias Rill.MessageStore.MessageData.Write

  @impl Rill.MessageStore.Database
  def get(%Session{} = session, stream_name, opts)
      when is_binary(stream_name) and is_list(opts) do
    server_call(session, {:get, stream_name, opts})
  end

  @impl Rill.MessageStore.Database
  def get_last(%Session{} = session, stream_name)
      when is_binary(stream_name) do
    server_call(session, {:get_last, stream_name})
  end

  @impl Rill.MessageStore.Database
  def put(%Session{} = session, %Write{} = msg, stream_name, opts)
      when is_binary(stream_name) and is_list(opts) do
    server_call(session, {:put, msg, stream_name, opts})
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
