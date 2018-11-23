defprotocol Rill.MessageStore.Ecto.Postgres.Session do
  @fallback_to_any true
  @spec get(session :: term()) :: term()
  def get(session)
end
