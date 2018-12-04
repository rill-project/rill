defmodule Rill.MessageStore.Ecto.Postgres.Session do
  alias Rill.MessageStore.Ecto.Postgres, as: MessageStore
  alias Rill.MessageStore.Ecto.Postgres.Database
  alias Rill.Session

  def new(repo) when is_atom(repo) do
    session = Session.new(MessageStore, Database)
    Session.put_config(session, :repo, repo)
  end
end
