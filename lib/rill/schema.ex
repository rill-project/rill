defmodule Rill.Schema do
  alias Rill.Schema.DataStructure

  @spec to_map(data :: term()) :: map()
  defdelegate to_map(data), to: DataStructure

  @callback build(data :: map()) :: struct()
  @callback to_map(data :: term()) :: map()
end
