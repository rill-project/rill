defmodule Rill.Logger.Text do
  alias Rill.MessageStore.MessageData.Read

  def message_data(%Read{} = message_data) do
    "Stream: #{message_data.stream_name}, Position: #{message_data.position}, GlobalPosition: #{
      message_data.global_position
    }, Type: #{message_data.type}"
  end
end
