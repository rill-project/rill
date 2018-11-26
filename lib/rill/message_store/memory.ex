defmodule Rill.MessageStore.Memory do
  @database Rill.MessageStore.Memory.Database
  use Rill.MessageStore, database: @database

  defmacro __using__(namespace: ns) do
    quote location: :keep do
      @spec read(
              stream_name :: String.t(),
              opts :: [Rill.MessageStore.Database.get_opts()],
              fun ::
                nil | (%Rill.MessageStore.MessageData.Read{}, term() -> term())
            ) :: Enumerable.t() | term()
      def read(stream_name, opts \\ [], fun \\ nil) do
        ns = unquote(ns)
        unquote(__MODULE__).read(ns, stream_name, opts, fun)
      end

      @spec write(
              message_or_messages :: struct() | [struct()],
              stream_name :: String.t(),
              opts :: [Rill.MessageStore.write_option()]
            ) :: non_neg_integer()
      def write(message_or_messages, stream_name, opts \\ []) do
        ns = unquote(ns)
        unquote(__MODULE__).write(ns, message_or_messages, stream_name, opts)
      end

      @spec write_initial(
              message :: struct(),
              stream_name :: String.t()
            ) :: non_neg_integer()
      def write_initial(message, stream_name) do
        ns = unquote(ns)
        unquote(__MODULE__).write_initial(ns, message, stream_name)
      end
    end
  end
end
