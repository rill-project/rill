defmodule Rill.MessageStore.Mnesia.Session do
  alias Rill.MessageStore.Mnesia, as: MessageStore
  alias Rill.MessageStore.Mnesia.Database
  alias Rill.Session

  @spec new(namespace :: String.t()) :: Session.t()
  def new(namespace) do
    session = Session.new(MessageStore, Database)
    Session.put_config(session, :namespace, namespace)
  end
end
