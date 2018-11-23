defmodule Rill.Identifier.UUID.Random do
  defdelegate get(), to: Ecto.UUID, as: :generate
end
