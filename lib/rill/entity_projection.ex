defmodule Rill.EntityProjection do
  use Rill.Kernel
  import Kernel, except: [apply: 2, apply: 3]

  alias Rill.MessageStore.MessageData.Read
  alias Rill.Messaging.Message.Dictionary

  @scribble tag: :consumer

  @callback apply(message :: struct(), entity :: term()) :: term()
  @optional_callbacks apply: 2

  @spec apply(
          projection :: module(),
          entity :: term(),
          message_data :: %Read{} | Enumerable.t()
        ) :: term()
  def apply(projection, entity, message_data) do
    dictionary = Dictionary.get_dictionary(projection)
    apply(projection, entity, dictionary, message_data)
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
    Log.trace tag: :apply do
      "Applying event (Type: #{message_data.type})"
    end

    msg = Dictionary.translate(dictionary, message_data)

    Log.trace tags: [:data, :message] do
      inspect(msg, pretty: true)
    end

    new_entity =
      if is_nil(msg) do
        entity
      else
        projection.apply(msg, entity)
      end

    Log.info tag: :apply do
      "Applied event (Type: #{message_data.type})"
    end

    Log.trace tags: [:data, :message] do
      inspect(msg, pretty: true)
    end

    new_entity
  end

  @spec apply(
          projection :: module(),
          entity :: term(),
          dictionary :: %Dictionary{},
          messages_data :: Enumerable.t()
        ) :: term()
  def apply(projection, entity, %Dictionary{} = dictionary, messages_data) do
    Enum.reduce(messages_data, entity, fn message_data, current_entity ->
      apply(projection, current_entity, dictionary, message_data)
    end)
  end

  defmacro __using__(_opts \\ []) do
    quote do
      use Rill.Messaging.Message.Dictionary
      @behaviour unquote(__MODULE__)
      import Kernel, except: [apply: 2, apply: 3]

      def apply(entity, %Rill.MessageStore.MessageData.Read{} = message_data) do
        unquote(__MODULE__).apply(__MODULE__, entity, message_data)
      end
    end
  end
end
