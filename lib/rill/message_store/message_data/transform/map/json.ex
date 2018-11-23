defmodule Rill.MessageStore.MessageData.Transform.Map.JSON do
  alias Rill.Casing

  @spec write(data :: map()) :: String.t()
  def write(%{} = data) do
    data =
      if is_nil(data[:metadata]) do
        data
      else
        metadata = Casing.to_camel(data[:metadata])
        Map.put(data, :metadata, metadata)
      end

    data
    |> Casing.to_camel()
    |> json_encode!()
  end

  def read(text) when is_binary(text) do
    data =
      text
      |> json_decode!()
      |> Casing.to_snake()

    data =
      if is_nil(data["metadata"]) do
        data
      else
        metadata =
          data["metadata"]
          |> Casing.to_snake()
          |> to_atom_keys()

        Map.put(data, "metadata", metadata)
      end

    to_atom_keys(data)
  end

  def to_atom_keys(%{} = data) do
    data
    |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
    |> Map.new()
  end

  def json_encode!(text, opts \\ []) do
    fun =
      :rill
      |> Application.get_env(:json)
      |> Keyword.fetch!(:encode)

    fun.(text, opts)
  end

  def json_decode!(text, opts \\ []) do
    fun =
      :rill
      |> Application.get_env(:json)
      |> Keyword.fetch!(:decode)

    fun.(text, opts)
  end
end
