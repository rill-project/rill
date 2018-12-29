defmodule Rill.MessageStore.Mnesia.Session do
  alias Rill.MessageStore.Mnesia, as: MessageStore
  alias Rill.MessageStore.Mnesia.Database
  alias Rill.Session

  @doc """
  Creates a new random session and returns it with the UUID used as namespace
  """
  @spec rand() :: {Session.t(), String.t()}
  def rand do
    id = Rill.Identifier.UUID.Random.get()
    {new(id), id}
  end

  @spec new(namespace :: String.t()) :: Session.t()
  def new(namespace) do
    session = Session.new(MessageStore, Database)
    Session.put_config(session, :namespace, namespace)
  end
end
