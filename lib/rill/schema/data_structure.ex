defprotocol Rill.Schema.DataStructure do
  @spec to_map(data :: term()) :: map()
  def to_map(data)
end
