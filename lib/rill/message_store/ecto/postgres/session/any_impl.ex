defimpl Rill.MessageStore.Ecto.Postgres.Session, for: Any do
  @spec get(session :: term()) :: module()
  def get(session), do: session
end
