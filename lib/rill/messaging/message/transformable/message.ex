defmodule Rill.Messaging.Message.Transformable.Message do
  alias Rill.MessageStore.MessageData.Write
  alias Rill.Messaging.Message.Metadata
  alias Rill.Messaging.Message

  @spec write(msg :: struct()) :: %Write{}
  def write(%{__struct__: _} = msg) do
    message_type = Message.message_type(msg)
    data = Message.to_map(msg)

    metadata =
      msg.metadata
      |> Metadata.to_map()
      |> Enum.filter(fn {_key, value} -> !is_nil(value) end)
      |> Map.new()

    %Write{}
    |> Map.put(:id, msg.id)
    |> Map.put(:type, message_type)
    |> Map.put(:data, data)
    |> Map.put(:metadata, metadata)
  end
end
