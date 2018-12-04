defmodule Rill.EntityProjection do
  alias Rill.MessageStore.MessageData.Read
  alias Rill.Messaging.Message.Dictionary

  @callback apply(message :: struct(), entity :: term()) :: term()
  @optional_callbacks apply: 2

  @spec apply(
          projection :: module(),
          entity :: term(),
          message_data :: %Read{} | Enumerable.t()
        ) :: term()
  def apply(projection, entity, message_data) do
    dictionary = Dictionary.get_dictionary(projection)
    __MODULE__.apply(projection, entity, dictionary, message_data)
  end

  @spec apply(
          projection :: module(),
          entity :: term(),
          dictionary :: %Dictionary{},
          message_data :: %Read{}
        ) :: term()
  def apply(
        projection,
        entity,
        %Dictionary{} = dictionary,
        %Read{} = message_data
      ) do
    msg = Dictionary.translate(dictionary, message_data)

    if is_nil(msg) do
      entity
    else
      projection.apply(msg, entity)
    end
  end

  @spec apply(
          projection :: module(),
          entity :: term(),
          dictionary :: %Dictionary{},
          messages_data :: Enumerable.t()
        ) :: term()
  def apply(projection, entity, %Dictionary{} = dictionary, messages_data) do
    Enum.reduce(messages_data, entity, fn message_data, current_entity ->
      __MODULE__.apply(projection, current_entity, dictionary, message_data)
    end)
  end

  defmacro __using__(_opts \\ []) do
    quote do
      use Rill.Messaging.Message.Dictionary
      @behaviour unquote(__MODULE__)

      def apply(entity, %Rill.MessageStore.MessageData.Read{} = message_data) do
        unquote(__MODULE__).apply(__MODULE__, entity, message_data)
      end
    end
  end
end
