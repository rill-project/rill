defmodule Rill.MessageStore.Memory.Database do
  # session could be anything you want. In Postgres is the atom for the Repo
  # module

  defmodule Defaults do
    @spec position() :: 0
    def position, do: 0
    @spec batch_size() :: 100
    def batch_size, do: 100
  end

  @behaviour Rill.MessageStore.Database

  alias Rill.MessageStore.Memory.Session
  alias Rill.MessageStore.MessageData.Write

  @impl Rill.MessageStore.Database
  def get(session, stream_name, opts)
  when is_binary(stream_name) and is_list(opts) do
    server_call session, {:get, stream_name, opts}
  end

  @impl Rill.MessageStore.Database
  def get_last(session, stream_name)
  when is_binary(stream_name) do
    server_call session, {:get_last, stream_name}
  end

  @impl Rill.MessageStore.Database
  def put(session, %Write{} = msg, stream_name, opts)
  when is_binary(stream_name) and is_list(opts) do
    server_call session, {:put, msg, stream_name, opts}
  end

  # just a wrapper for calling genserver
  defp server_call(session, params) when is_tuple(params) do
    {:ok, result} = GenServer.call(Session.get(session), params)
    result
  end
end
