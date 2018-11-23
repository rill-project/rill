defimpl Rill.Schema.DataStructure, for: Any do
  @spec to_map(data :: term()) :: map()
  def to_map(%{__struct__: _} = data), do: Map.from_struct(data)
  def to_map(%{} = data), do: data
end
