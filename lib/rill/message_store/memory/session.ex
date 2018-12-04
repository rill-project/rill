defmodule Rill.MessageStore.Memory.Session do
  alias Rill.MessageStore.Memory, as: MessageStore
  alias Rill.MessageStore.Memory.Database
  alias Rill.Session

  def new(pid) do
    session = Session.new(MessageStore, Database)
    Session.put_config(session, :pid, pid)
  end
end
