defmodule Rill.MessageStore do
  alias Rill.MessageStore.MessageData.Read
  alias Rill.Session
  alias Rill.MessageStore.StreamName

  @type read_option ::
          {:position, non_neg_integer()}
          | {:batch_size, pos_integer()}
  @doc """
  Returned enumerable must be a stream from the given position until the end
  of the stream. If `fun` is passed, the stream will instead be reduced, with
  an accumulator value initially being `nil` and successive values will be
  those returned by `fun`
  """
  @callback read(
              session :: Session.t(),
              stream_name :: StreamName.t(),
              opts :: [read_option()],
              fun :: nil | (%Read{}, term() -> term())
            ) :: Enumerable.t() | term()

  @type write_option ::
          {:expected_version, Rill.MessageStore.ExpectedVersion.t()}
          | {:reply_stream_name, String.t() | nil}
  @callback write(
              session :: Session.t(),
              message_or_messages :: struct() | [struct()],
              stream_name :: StreamName.t(),
              opts :: [write_option()]
            ) :: non_neg_integer()
  @callback write_initial(
              session :: Session.t(),
              message :: struct(),
              stream_name :: StreamName.t()
            ) :: non_neg_integer()
  @doc """
  Behaves like `write_initial` but instead of raising, it returns `nil`
  """
  @callback write_once(
              session :: Session.t(),
              message :: struct(),
              stream_name :: StreamName.t()
            ) :: nil | non_neg_integer()

  def read(%Session{} = session, stream_name, opts \\ [], fun \\ nil) do
    session.message_store.read(session, stream_name, opts, fun)
  end

  def write(%Session{} = session, message_or_messages, stream_name, opts \\ []) do
    session.message_store.write(session, message_or_messages, stream_name, opts)
  end

  def write_initial(%Session{} = session, message, stream_name) do
    session.message_store.write_initial(session, message, stream_name)
  end

  def write_once(%Session{} = session, message, stream_name) do
    session.message_store.write_once(session, message, stream_name)
  end

  defmacro __using__(_opts \\ []) do
    base = Rill.MessageStore.Base

    quote location: :keep do
      @behaviour unquote(__MODULE__)

      def read(session, stream_name, opts \\ [], fun \\ nil) do
        unquote(base).read(session, stream_name, opts, fun)
      end

      def write(session, message_or_messages, stream_name, opts \\ []) do
        unquote(base).write(session, message_or_messages, stream_name, opts)
      end

      def write_initial(session, message, stream_name) do
        unquote(base).write_initial(session, message, stream_name)
      end

      def write_once(session, message, stream_name) do
        unquote(base).write_once(session, message, stream_name)
      end

      defoverridable unquote(__MODULE__)
      defoverridable read: 2, read: 3, write: 3
    end
  end
end
