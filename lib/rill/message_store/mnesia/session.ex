defmodule Rill.MessageStore.Mnesia.Session do
  alias Rill.MessageStore.Mnesia, as: MessageStore
  alias Rill.MessageStore.Mnesia.Database
  alias Rill.Session

  def new(namespace) when is_atom(namespace) do
    session = Session.new(MessageStore, Database)
    Session.put_config(session, :namespace, namespace)
  end
end
