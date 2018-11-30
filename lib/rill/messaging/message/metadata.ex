defmodule Rill.Messaging.Message.Metadata do
  alias Rill.Messaging.Category
  alias Rill.MessageStore.StreamName

  defstruct [
    :stream_name,
    :position,
    :global_position,
    :causation_message_stream_name,
    :causation_message_position,
    :causation_message_global_position,
    :correlation_stream_name,
    :reply_stream_name,
    :time,
    :schema_version
  ]

  @type t :: %__MODULE__{
          stream_name: String.t(),
          position: non_neg_integer(),
          global_position: pos_integer(),
          causation_message_stream_name: String.t() | nil,
          causation_message_position: non_neg_integer() | nil,
          causation_message_global_position: pos_integer() | nil,
          correlation_stream_name: String.t() | nil,
          reply_stream_name: String.t() | nil,
          time: NaiveDateTime.t(),
          schema_version: String.t() | nil
        }

  def get_identifier(%__MODULE__{stream_name: nil}), do: nil
  def get_identifier(%__MODULE__{position: nil}), do: nil

  @spec get_identifier(metadata :: %__MODULE__{}) :: String.t() | nil
  def get_identifier(%__MODULE__{} = metadata) do
    %{stream_name: stream_name, position: position} = metadata
    "#{stream_name}/#{position}"
  end

  def get_causation_message_identifier(%__MODULE__{
        causation_message_stream_name: nil
      }),
      do: nil

  def get_causation_message_identifier(%__MODULE__{
        causation_message_position: nil
      }),
      do: nil

  @spec get_causation_message_identifier(metadata :: %__MODULE__{}) ::
          String.t() | nil
  def get_causation_message_identifier(%__MODULE__{} = metadata) do
    %{causation_message_stream_name: stream_name} = metadata
    %{causation_message_position: position} = metadata
    "#{stream_name}/#{position}"
  end

  @spec follow(metadata :: %__MODULE__{}, preceding_metadata :: %__MODULE__{}) ::
          %__MODULE__{}
  def follow(%__MODULE__{} = metadata, %__MODULE__{} = preceding_metadata) do
    %{
      stream_name: stream_name,
      position: position,
      global_position: global_position,
      correlation_stream_name: correlation_stream_name,
      reply_stream_name: reply_stream_name
    } = preceding_metadata

    metadata
    |> Map.put(:causation_message_stream_name, stream_name)
    |> Map.put(:causation_message_position, position)
    |> Map.put(:causation_message_global_position, global_position)
    |> Map.put(:correlation_stream_name, correlation_stream_name)
    |> Map.put(:reply_stream_name, reply_stream_name)
  end

  @spec follows?(metadata :: %__MODULE__{}, preceding :: %__MODULE__{}) ::
          boolean()
  def follows?(%__MODULE__{} = metadata, %__MODULE__{} = preceding) do
    metadata.causation_message_stream_name == preceding.stream_name &&
      metadata.causation_message_position == preceding.position &&
      metadata.causation_message_global_position == preceding.global_position &&
      metadata.reply_stream_name == preceding.reply_stream_name
  end

  @spec clear_reply_stream_name(metadata :: %__MODULE__{}) :: %__MODULE__{}
  def clear_reply_stream_name(%__MODULE__{} = metadata) do
    Map.put(metadata, :reply_stream_name, nil)
  end

  @spec reply?(metadata :: %__MODULE__{}) :: boolean()
  def reply?(%__MODULE__{reply_stream_name: nil}), do: false
  def reply?(%__MODULE__{reply_stream_name: _}), do: true

  @spec correlate(metadata :: %__MODULE__{}, stream_name :: String.t()) ::
          %__MODULE__{}
  def correlate(%__MODULE__{} = metadata, stream_name)
      when is_binary(stream_name) do
    Map.put(metadata, :correlation_stream_name, stream_name)
  end

  @spec correlated?(metadata :: %__MODULE__{}, stream_name :: String.t()) ::
          boolean()
  def correlated?(%__MODULE__{correlation_stream_name: nil}, _), do: false

  def correlated?(%__MODULE__{} = metadata, stream_name) do
    correlation_stream_name = metadata.correlation_stream_name

    stream_name = Category.normalize(stream_name)

    correlation_stream_name =
      if StreamName.category?(stream_name) do
        StreamName.get_category(correlation_stream_name)
      else
        correlation_stream_name
      end

    correlation_stream_name == stream_name
  end

  @spec transient_attributes() :: [atom()]
  def transient_attributes do
    [
      :stream_name,
      :position,
      :global_position,
      :time
    ]
  end

  @doc "Builds metadata instance and sets existing fields based on `data`"
  @spec build(data :: map() | struct()) :: %__MODULE__{}
  def build(data \\ %{}) do
    {new_instance, _} = MapCopy.copy_existing(%__MODULE__{}, data)
    new_instance
  end

  def to_map(%__MODULE__{} = metadata) do
    Map.from_struct(metadata)
  end
end
