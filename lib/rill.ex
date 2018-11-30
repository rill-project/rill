defmodule Rill do
  def get_message_store do
    Application.get_env(:rill, :message_store)
  end

  def get_database do
    Application.get_env(:rill, :database)
  end

  def message(_opts) do
    quote do
      use Rill.Messaging.Message
    end
  end

  def projection(_opts) do
    quote do
      use Rill.EntityProjection
    end
  end

  def store(opts) do
    message_store = get_message_store()
    opts = Keyword.merge([accessor: message_store], opts)

    quote do
      use Rill.EntityStore, unquote(opts)
    end
  end

  def component(children) do
    quote do
      use Rill.ComponentHost, unquote(children)
    end
  end

  def consumer(opts) do
    database = get_database()
    opts = Keyword.merge([reader: database], opts)

    quote do
      use Rill.Consumer, unquote(opts)
    end
  end

  def handler(_opts) do
    message_store = get_message_store()

    quote do
      use Rill.Messaging.Handler
      alias unquote(message_store), as: MessageStore
      alias Rill.Messaging.Message

      import Rill.MessageStore.StreamName,
        only: [stream_name: 1, stream_name: 2, stream_name: 3]
    end
  end

  defmacro __using__(which, opts \\ []) when is_atom(which) do
    case which do
      :get_database -> raise "Invalid module"
      :get_message_store -> raise "Invalid module"
      func -> apply(__MODULE__, func, [opts])
    end
  end
end
