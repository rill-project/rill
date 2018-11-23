defimpl Rill.MessageStore.Ecto.Postgres.Session, for: Any do
  def get(session), do: session
end
