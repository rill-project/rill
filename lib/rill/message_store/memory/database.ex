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
    memory_session = Session.get(session)
    # TODO: Implement
    []
  end

  @impl Rill.MessageStore.Database
  def get_last(session, stream_name)
      when is_binary(stream_name) do
    memory_session = Session.get(session)
    # TODO: Implement
  end

  @impl Rill.MessageStore.Database
  def put(session, %Write{} = msg, stream_name, opts)
      when is_binary(stream_name) and is_list(opts) do
    memory_session = Session.get(session)
    # TODO: Implement
  end
end
