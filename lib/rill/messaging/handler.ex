defmodule Rill.Messaging.Handler do
  alias Rill.MessageStore.MessageData.Read
  alias Rill.Messaging.Message.Dictionary

  @callback handle(message :: struct()) :: no_return()
  @optional_callbacks handle: 1

  @spec handle(
          handler :: module(),
          message_data :: %Read{} | Enumerable.t()
        ) :: no_return()
  def handle(handler, message_data) do
    dictionary = Dictionary.get_dictionary(handler)
    __MODULE__.handle(handler, dictionary, message_data)
  end

  @spec handle(
          handler :: module(),
          dictionary :: %Dictionary{},
          message_data :: %Read{}
        ) :: no_return()
  def handle(
        handler,
        %Dictionary{} = dictionary,
        %Read{} = message_data
      ) do
    msg = Dictionary.translate(dictionary, message_data)

    if is_nil(msg) do
      nil
    else
      handler.handle(msg)
    end
  end

  @spec handle(
          handler :: module(),
          dictionary :: %Dictionary{},
          messages_data :: Enumerable.t()
        ) :: no_return()
  def handle(handler, %Dictionary{} = dictionary, messages_data) do
    Enum.each(messages_data, fn message_data ->
      __MODULE__.handle(handler, dictionary, message_data)
    end)
  end

  defmacro __using__(_opts \\ []) do
    quote do
      use Rill.Messaging.Message.Dictionary
      @behaviour unquote(__MODULE__)
    end
  end
end
