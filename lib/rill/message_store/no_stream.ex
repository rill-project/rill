defmodule Rill.MessageStore.NoStream do
  @spec name() :: :no_stream
  def name, do: :no_stream
  @spec version() :: -1
  def version, do: -1
end
