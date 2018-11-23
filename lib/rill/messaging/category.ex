defmodule Rill.Messaging.Category do
  @spec normalize(category :: String.t()) :: String.t()
  def normalize(category) do
    category
    |> to_string()
    |> Rill.Casing.to_camel()
  end
end
