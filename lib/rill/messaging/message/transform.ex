defmodule Rill.Messaging.Message.Transform do
  alias Rill.Messaging.Message.Transformable
  alias Rill.MessageStore.MessageData.Write

  @spec write(msg :: struct()) :: %Write{}
  defdelegate write(msg), to: Transformable

  def read(%{__struct__: _} = message_data) do
    message_data
    |> Map.from_struct()
    |> read()
  end

  @spec read(data :: map()) :: map()
  def read(%{} = data) do
    metadata = data[:metadata] || %{}

    metadata
    |> Map.put(:stream_name, data[:stream_name])
    |> Map.put(:position, data[:position])
    |> Map.put(:global_position, data[:global_position])
    |> Map.put(:time, data[:time])

    Map.put(data, :metadata, metadata)
  end
end
