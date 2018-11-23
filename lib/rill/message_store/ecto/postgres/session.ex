defprotocol Rill.MessageStore.Ecto.Postgres.Session do
  @fallback_to_any true
  def get(session)
end
