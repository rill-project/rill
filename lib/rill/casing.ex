defmodule Rill.Casing do
  @type convertible :: String.t() | map() | atom()
  @type converted :: String.t() | map()
  @type converter :: (convertible() -> converted())

  @spec to_camel(data :: convertible()) :: converted()
  def to_camel(atom) when is_atom(atom), do: atom |> to_string() |> to_camel()
  def to_camel(text) when is_binary(text), do: Recase.to_camel(text)
  def to_camel(%{} = data), do: to_string_case(data, &to_camel/1)

  @spec to_snake(data :: convertible()) :: converted()
  def to_snake(atom) when is_atom(atom), do: atom |> to_string() |> to_snake()
  def to_snake(text) when is_binary(text), do: Recase.to_snake(text)
  def to_snake(%{} = data), do: to_string_case(data, &to_snake/1)

  @spec to_string_case(data :: convertible(), fun :: converter()) :: converted()
  def to_string_case(text, fun) when is_binary(text) and is_function(fun) do
    text
    |> to_string()
    |> fun.()
  end

  def to_string_case(atom, fun) when is_atom(atom) and is_function(fun) do
    atom
    |> to_string()
    |> to_string_case(fun)
  end

  def to_string_case(%{} = data, fun) when is_function(fun) do
    data
    |> Enum.map(fn {key, value} -> {to_string_case(key, fun), value} end)
    |> Map.new()
  end
end
