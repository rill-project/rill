defmodule Rill.Messaging.Message do
  defmodule KeyError do
    defexception [:message]
  end

  alias Rill.Messaging.Message.Metadata
  alias Rill.MessageStore.MessageData.Read

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
      @behaviour Rill.Schema
      defstruct(unquote(attrs))

      defimpl Rill.Schema.DataStructure do
        def to_map(data), do: @for.to_map(data)
      end

      def to_map(%__MODULE__{} = data) do
        Rill.Messaging.Message.to_map(data)
      end

      def build(%Read{} = message_data) do
        data = message_data.data
        metadata = message_data.metadata

        msg = unquote(__MODULE__).build(__MODULE__, data, metadata)
        Map.put(msg, :id, message_data.id)
      end

      defdelegate correlate(message, correlation_stream_name),
        to: Rill.Messaging.Message

      @spec follow(preceding_message :: struct()) :: struct()
      def follow(%{} = preceding_message) do
        Rill.Messaging.Message.follow(__MODULE__, preceding_message)
      end

      @spec follow(
              preceding_message :: struct(),
              subsequent_message :: module() | struct()
            ) :: struct()
      def follow(%{} = preceding_message, subsequent_message) do
        Rill.Messaging.Message.follow(
          __MODULE__,
          preceding_message,
          subsequent_message
        )
      end

      defoverridable Rill.Schema
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
    Rill.Casing.to_snake(name)
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

  @doc "Builds struct for `struct_name`"
  @spec build(struct_name :: module(), data :: map(), metadata :: map()) ::
          struct()
  def build(struct_name, data \\ nil, metadata \\ nil) do
    data = data || %{}

    metadata =
      if is_nil(metadata),
        do: %Metadata{},
        else: Metadata.build(metadata)

    instance = struct(struct_name)
    {new_instance, _} = MapCopy.copy_existing(instance, data)

    Map.put(new_instance, :metadata, metadata)
  end

  def build_metadata(nil), do: %Metadata{}

  @spec build_metadata(metadata :: %Metadata{} | nil) :: %Metadata{}
  def build_metadata(%Metadata{} = metadata) do
    metadata
    |> Metadata.to_map()
    |> Metadata.build()
  end

  @doc "Builds struct for `struct_name` with `correlation_stream_name` set"
  @spec correlate(
          struct_name :: module(),
          correlation_stream_name :: String.t()
        ) :: struct()
  def correlate(struct_name, correlation_stream_name)
      when is_atom(struct_name) and is_binary(correlation_stream_name) do
    map = build(struct_name)

    metadata =
      Map.put(map.metadata, :correlation_stream_name, correlation_stream_name)

    Map.put(map, :metadata, metadata)
  end

  @spec correlate(message :: struct(), correlation_stream_name :: String.t()) ::
          struct()
  def correlate(%{} = message, correlation_stream_name)
      when is_binary(correlation_stream_name) do
    metadata = Metadata.correlate(message.metadata, correlation_stream_name)

    Map.put(message, :metadata, metadata)
  end

  @type copy_opts :: {:metadata, nil | %Metadata{}}
  @spec copy(
          source :: struct(),
          receiver :: struct(),
          opts :: [copy_opts()]
        ) :: struct()
  def copy(%{} = source, %{} = receiver, opts \\ []) do
    metadata = Keyword.get(opts, :metadata)
    {new_receiver, _} = MapCopy.copy_existing(receiver, source)

    if is_nil(metadata) do
      new_receiver
    else
      {new_metadata, _} = MapCopy.copy_existing(new_receiver.metadata, metadata)
      Map.put(new_receiver, :metadata, new_metadata)
    end
  end

  @spec follow(
          preceding_message :: struct(),
          subsequent_message :: struct()
        ) :: struct()
  def follow(%{} = preceding_message, %{} = subsequent_message) do
    struct_name = subsequent_message.__struct__
    follow(struct_name, preceding_message, subsequent_message)
  end

  @spec follow(
          struct_name :: module(),
          preceding_message :: struct()
        ) :: struct()
  def follow(struct_name, %{} = preceding_message) do
    follow(struct_name, preceding_message, struct_name)
  end

  @spec follow(
          struct_name :: module(),
          preceding_message :: struct(),
          subsequent_message :: module()
        ) :: struct()
  def follow(struct_name, preceding_message, subsequent_message)
      when is_atom(subsequent_message) do
    subsequent_message = build(subsequent_message)
    follow(struct_name, preceding_message, subsequent_message)
  end

  @spec follow(
          struct_name :: module(),
          preceding_message :: struct(),
          subsequent_message :: struct()
        ) :: struct()
  def follow(struct_name, %{} = preceding_message, %{} = subsequent_message)
      when is_atom(struct_name) do
    {subsequent_message, _} =
      MapCopy.copy_existing(subsequent_message, preceding_message)

    metadata =
      Metadata.follow(
        subsequent_message.metadata,
        preceding_message.metadata
      )

    Map.put(subsequent_message, :metadata, metadata)
  end

  @spec to_map(msg :: struct()) :: map()
  def to_map(%{id: _, metadata: _} = msg) do
    msg
    |> Map.from_struct()
    |> Map.drop([:id, :metadata])
  end

  defp to_atom(value) when is_atom(value), do: value
  defp to_atom(value) when is_binary(value), do: String.to_atom(value)
end
