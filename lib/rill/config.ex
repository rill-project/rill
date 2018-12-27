defmodule Rill.Config do
  @moduledoc false

  def defaults do
    [
      json: [encode: &Jason.encode!/2, decode: &Jason.decode!/2]
    ]
  end

  def get, do: Keyword.merge(defaults(), Application.get_all_env(:rill))
  def get(key), do: get(key, nil)
  def get(key, default), do: Keyword.get(get(), key) || default

  def put(key, value) do
    Application.put_env(:rill, key, value)
  end

  def put(config) do
    Enum.each(config, fn {key, value} ->
      put(key, value)
    end)
  end
end
