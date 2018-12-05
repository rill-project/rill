defmodule Rill.MessageStore do
  alias Rill.MessageStore.MessageData.Read
  alias Rill.Session

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
              stream_name :: String.t(),
              opts :: [read_option()],
              fun :: nil | (%Read{}, term() -> term())
            ) :: Enumerable.t() | term()

  @type write_option ::
          {:expected_version, Rill.MessageStore.ExpectedVersion.t()}
          | {:reply_stream_name, String.t() | nil}
  @callback write(
              session :: Session.t(),
              message_or_messages :: struct() | [struct()],
              stream_name :: String.t(),
              opts :: [write_option()]
            ) :: non_neg_integer()
  @callback write_initial(
              session :: Session.t(),
              message :: struct(),
              stream_name :: String.t()
            ) :: non_neg_integer()

  def read(%Session{} = session, stream_name, opts \\ [], fun \\ nil) do
    session.message_store.read(session, stream_name, opts, fun)
  end

  def write(%Session{} = session, message_or_messages, stream_name, opts \\ []) do
    session.message_store.write(session, message_or_messages, stream_name, opts)
  end

  def write_initial(%Session{} = session, message, stream_name) do
    session.message_store.write_initial(session, message, stream_name)
  end

  @spec handle(
          session :: Session.t(),
          stream_name :: String.t(),
          handler :: module(),
          times :: pos_integer(),
          opts :: [read_option()]
        ) :: Session.t()
  def handle(session, stream_name, handler),
    do: handle(session, stream_name, handler, 1, [])

  def handle(session, stream_name, handler, opts) when is_list(opts),
    do: handle(session, stream_name, handler, 1, opts)

  def handle(session, stream_name, handler, times) when is_integer(times),
    do: handle(session, stream_name, handler, times, [])

  def handle(%Session{} = session, stream_name, handler, times, opts) do
    repeat_times = Range.new(1, times)

    Enum.each(repeat_times, fn _ ->
      session
      |> read(stream_name, opts)
      |> Enum.each(fn message -> handler.handle(session, message) end)
    end)

    session
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

      defoverridable unquote(__MODULE__)
      defoverridable read: 2, read: 3, write: 3
    end
  end
end
