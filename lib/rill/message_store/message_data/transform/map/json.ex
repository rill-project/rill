defmodule Rill.MessageStore.MessageData.Transform.Map.JSON do
  use Rill.Kernel
  alias Rill.Casing

  @spec write(data :: map()) :: String.t()
  def write(%{} = data) do
    data
    |> Casing.to_camel()
    |> json_encode!()
  end

  @spec read(data :: String.t() | map()) :: map()
  def read(text) when is_binary(text), do: text |> json_decode!() |> read()

  def read(%{} = data) do
    data
    |> Casing.to_snake()
    |> to_atom_keys()
  end

  def to_atom_keys(%{} = data) do
    data
    |> Enum.map(fn {key, value} ->
      {key |> to_string() |> String.to_atom(), value}
    end)
    |> Map.new()
  end

  def json_encode!(text, opts \\ []) do
    fun =
      Config.get(:json, [])
      |> Keyword.fetch!(:encode)

    fun.(text, opts)
  end

  def json_decode!(text, opts \\ []) do
    fun =
      Config.get(:json, [])
      |> Keyword.fetch!(:decode)

    fun.(text, opts)
  end
end
