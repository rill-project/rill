defmodule Rill.Identifier.UUID.Random do
  @spec get() :: String.t()
  defdelegate get(), to: Ecto.UUID, as: :generate
end
