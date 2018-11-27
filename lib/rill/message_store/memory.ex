defmodule Rill.MessageStore.Memory do
  @database Rill.MessageStore.Memory.Database
  use Rill.MessageStore, database: @database

  defmacro __using__(namespace: ns) do
    quote location: :keep do
      @behaviour Rill.MessageStore.Accessor

      def read(stream_name, opts \\ [], fun \\ nil) do
        ns = unquote(ns)
        unquote(__MODULE__).read(ns, stream_name, opts, fun)
      end

      def write(message_or_messages, stream_name, opts \\ []) do
        ns = unquote(ns)
        unquote(__MODULE__).write(ns, message_or_messages, stream_name, opts)
      end

      def write_initial(message, stream_name) do
        ns = unquote(ns)
        unquote(__MODULE__).write_initial(ns, message, stream_name)
      end
    end
  end
end
