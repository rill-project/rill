defmodule Rill.MessageStore.StreamName do
  defmodule Error do
    defexception [:message]
  end

  @type t :: String.t()

  @type stream_name_opts ::
          {:type, String.t() | nil}
          | {:types, [String.t()] | nil}
  @spec stream_name(
          category_name :: String.t(),
          id :: String.t() | nil,
          opts :: [stream_name_opts()]
        ) :: boolean()
  def stream_name(category_name), do: stream_name(category_name, nil, [])
  def stream_name(category_name, id), do: stream_name(category_name, id, [])

  def stream_name(nil, _id, _opts) do
    raise Error, message: "Category name must not be omitted from stream name"
  end

  def stream_name(category_name, id, opts) when is_list(opts) do
    type = Keyword.get(opts, :type)
    types = Keyword.get(opts, :types)

    types = to_list(types)

    types =
      if is_nil(type),
        do: types,
        else: [type | types]

    type_list =
      case types do
        [] -> nil
        list -> Enum.join(list, "+")
      end

    name = category_name

    name =
      if is_nil(type_list),
        do: name,
        else: "#{name}:#{type_list}"

    if is_nil(id),
      do: name,
      else: "#{name}-#{id}"
  end

  @spec get_id(stream_name :: t()) :: String.t() | nil
  def get_id(stream_name) do
    category_name = get_category(stream_name)

    id =
      stream_name
      |> trim_leading(category_name)
      |> trim_leading("-")

    case id do
      "" -> nil
      _ -> id
    end
  end

  @spec category?(stream_name :: t()) :: boolean()
  def category?(stream_name), do: !String.contains?(stream_name, "-")

  @spec get_category(stream_name :: t()) :: String.t()
  def get_category(stream_name) do
    stream_name
    |> String.split("-")
    |> List.first()
  end

  @spec get_type_list(stream_name :: t()) :: String.t() | nil
  def get_type_list(stream_name) do
    category_name = get_category(stream_name)

    type =
      category_name
      |> String.split(":")
      |> List.last()

    if String.starts_with?(category_name, type),
      do: nil,
      else: type
  end

  @spec get_types(stream_name :: t()) :: [String.t()]
  def get_types(stream_name) do
    type_list = get_type_list(stream_name)

    if is_nil(type_list),
      do: [],
      else: String.split(type_list, "+")
  end

  @spec get_entity_name(stream_name :: t()) :: String.t()
  def get_entity_name(stream_name) do
    stream_name
    |> get_category()
    |> String.split(":")
    |> List.first()
  end

  defp to_list(nil), do: []
  defp to_list(list) when is_list(list), do: list
  defp trim_leading(text, ""), do: text
  defp trim_leading(text, match), do: String.trim_leading(text, match)
end
