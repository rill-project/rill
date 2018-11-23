defimpl Rill.MessageStore.Memory.Session, for: Any do
  @spec get(session :: term()) :: module()
  def get(session), do: session
end
