defmodule Rill.MessageStore.Ecto.Postgres.Database.Deserialize do
  alias Rill.MessageStore.MessageData.Transform.Map.JSON

  @spec data(serialized_data :: nil | String.t() | map()) :: map()
  def data(nil), do: nil
  def data(serialized_data), do: JSON.read(serialized_data)

  @spec metadata(serialized_metadata :: nil | String.t() | map()) :: map()
  def metadata(nil), do: nil
  def metadata(serialized_metadata), do: JSON.read(serialized_metadata)
end
