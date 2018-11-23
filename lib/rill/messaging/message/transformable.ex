defprotocol Rill.Messaging.Message.Transformable do
  alias Rill.MessageStore.MessageData.Write

  @fallback_to_any true

  @spec write(msg :: struct()) :: %Write{}
  def write(msg)
end
