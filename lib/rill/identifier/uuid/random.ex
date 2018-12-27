defmodule Rill.Identifier.UUID.Random do
  @spec get() :: String.t()
  defdelegate get(), to: UUID, as: :uuid4
end
