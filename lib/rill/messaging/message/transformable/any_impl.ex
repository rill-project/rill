defimpl Rill.Messaging.Message.Transformable, for: Any do
  alias Rill.MessageStore.MessageData.Write
  alias Rill.Messaging.Message.Transformable.Message, as: TransformableMessage

  @spec write(msg :: struct()) :: %Write{}
  defdelegate write(msg), to: TransformableMessage
end
