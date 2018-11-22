defmodule Rill.Messaging.Message do
  defmodule KeyError do
    defexception [:message]
  end

  alias Rill.Messaging.Message.Metadata

  @type message_or_type :: String.t() | atom() | struct()

  @doc """
  Behaves like `defstruct/1`, but doesn't allow to use attributes named `:id`
  or `:metadata` (reserved).
  The attribute `:id` is automatically defined with default `nil`.
  The attribute `:metadata` is automatically defined with default
  `%Rill.Messaging.Message.Metadata{}`
  """
  @spec defmessage(attrs :: [atom()] | keyword()) :: any()
  defmacro defmessage(attrs) when is_list(attrs) do
    attrs =
      Enum.map(attrs, fn attr ->
        if is_tuple(attr), do: to_atom(attr), else: {to_atom(attr), nil}
      end)

    if Keyword.has_key?(attrs, :id) or Keyword.has_key?(attrs, :metadata) do
      raise KeyError, message: "Fields :id and :metadata are reserved"
    end

    attrs =
      attrs
      |> Keyword.merge(id: nil, metadata: %Rill.Messaging.Message.Metadata{})
      |> Macro.escape()

    quote location: :keep do
      defstruct(unquote(attrs))
    end
  end

  @doc """
  Provides `defmessage/1` macro which allows creation of struct with required
  message keys (:id, :metadata)
  """
  defmacro __using__(_opts \\ []) do
    quote location: :keep do
      require unquote(__MODULE__)
      import unquote(__MODULE__), only: [defmessage: 1]
    end
  end

  @spec transient_attributes() :: [atom()]
  def transient_attributes do
    [
      :id,
      :metadata
    ]
  end

  @spec message_type(msg :: message_or_type()) :: [atom()]
  def message_type(msg) do
    msg
    |> struct_name()
    |> Module.split()
    |> List.last()
  end

  @spec message_type?(msg :: message_or_type(), type :: String.t()) :: boolean()
  def message_type?(msg, type) do
    message_type(msg) == type
  end

  @spec message_name(msg :: message_or_type()) :: String.t()
  def message_name(msg) do
    msg
    |> message_type()
    |> canonize_name()
  end

  @spec canonize_name(name :: String.t()) :: String.t()
  def canonize_name(name) do
    Recase.to_snake(name)
  end

  @spec struct_name(msg :: message_or_type()) :: String.t()
  def struct_name(msg) when is_binary(msg), do: msg
  def struct_name(msg) when is_atom(msg), do: to_string(msg)
  def struct_name(%{__struct__: module}), do: to_string(module)

  @spec follows?(%{metadata: %Metadata{}}, %{metadata: %Metadata{}}) ::
          boolean()
  def follows?(
        %{metadata: %Metadata{} = metadata},
        %{metadata: %Metadata{} = other_metadata}
      ) do
    Metadata.follows?(metadata, other_metadata)
  end

  # build
  # set_attributes

  defp to_atom(value) when is_atom(value), do: value
  defp to_atom(value) when is_binary(value), do: String.to_atom(value)
end
