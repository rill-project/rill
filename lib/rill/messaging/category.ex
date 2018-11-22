defmodule Rill.Messaging.Category do
  @spec normalize(category :: String.t()) :: String.t()
  def normalize(category) do
    category
    |> to_string()
    |> Recase.to_camel()
  end
end
