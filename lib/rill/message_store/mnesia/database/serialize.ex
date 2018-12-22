defmodule Rill.MessageStore.Mnesia.Database.Serialize do
  alias Rill.MessageStore.MessageData.Transform.Map.JSON

  @spec data(data :: map() | nil) :: String.t()
  def data(%{} = data) when data == %{}, do: data(nil)
  def data(nil), do: nil
  def data(%{} = data), do: JSON.write(data)

  @spec metadata(metadata :: map() | nil) :: String.t()
  def metadata(%{} = metadata) when metadata == %{}, do: metadata(nil)
  def metadata(nil), do: nil
  def metadata(%{} = metadata), do: JSON.write(metadata)
end
