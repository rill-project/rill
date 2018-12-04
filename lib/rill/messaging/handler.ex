defmodule Rill.Messaging.Handler do
  alias Rill.Session
  alias Rill.MessageStore.MessageData.Read
  alias Rill.Messaging.Message.Dictionary

  @callback handle(message :: struct(), session :: Session.t()) :: no_return()
  @optional_callbacks handle: 2

  @spec handle(
          session :: Session.t(),
          handler :: module(),
          message_data :: %Read{} | Enumerable.t()
        ) :: no_return()
  def handle(%Session{} = session, handler, message_data) do
    dictionary = Dictionary.get_dictionary(handler)
    __MODULE__.handle(session, handler, dictionary, message_data)
  end

  @spec handle(
          session :: Session.t(),
          handler :: module(),
          dictionary :: %Dictionary{},
          message_data :: %Read{}
        ) :: no_return()
  def handle(
        %Session{} = session,
        handler,
        %Dictionary{} = dictionary,
        %Read{} = message_data
      ) do
    msg = Dictionary.translate(dictionary, message_data)

    if is_nil(msg) do
      nil
    else
      handler.handle(msg, session)
    end
  end

  @spec handle(
          session :: Session.t(),
          handler :: module(),
          dictionary :: %Dictionary{},
          messages_data :: Enumerable.t()
        ) :: no_return()
  def handle(
        %Session{} = session,
        handler,
        %Dictionary{} = dictionary,
        messages_data
      ) do
    Enum.each(messages_data, fn message_data ->
      __MODULE__.handle(session, handler, dictionary, message_data)
    end)
  end

  defmacro __using__(_opts \\ []) do
    quote do
      use Rill.Messaging.Message.Dictionary
      @behaviour unquote(__MODULE__)

      def handle(
            %Rill.Session{} = session,
            %Rill.MessageStore.MessageData.Read{} = message_data
          ) do
        unquote(__MODULE__).handle(session, __MODULE__, message_data)
      end
    end
  end
end
