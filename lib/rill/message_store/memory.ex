defmodule Rill.MessageStore.Memory do
  use Rill.MessageStore

  def start_link(opts \\ []) do
    __MODULE__.Server.start_link(opts)
  end
end
