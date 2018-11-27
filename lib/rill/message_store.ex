defmodule Rill.MessageStore do
  alias Rill.Messaging.Message.Transform
  alias Rill.MessageStore.MessageData.Read
  alias Rill.MessageStore.StreamName
  alias Rill.MessageStore.ExpectedVersion

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
              session :: term(),
              stream_name :: String.t(),
              opts :: [read_option()],
              fun :: nil | (%Read{}, term() -> term())
            ) :: Enumerable.t() | term()

  @type write_option ::
          {:expected_version, Rill.MessageStore.ExpectedVersion.t()}
          | {:reply_stream_name, String.t() | nil}
  @callback write(
              session :: term(),
              message_or_messages :: struct() | [struct()],
              stream_name :: String.t(),
              opts :: [write_option()]
            ) :: non_neg_integer()
  @callback write_initial(
              session :: term(),
              message :: struct(),
              stream_name :: String.t()
            ) :: non_neg_integer()

  @spec read(
          session :: term(),
          database :: module(),
          stream_name :: String.t(),
          opts :: [read_option()],
          fun :: nil | (%Read{}, term() -> term())
        ) :: Enumerable.t() | term()
  def read(session, database, stream_name, opts \\ [], fun \\ nil) do
    start_position = Keyword.get(opts, :position)
    start_fun = fn -> start_position end
    after_fun = fn _position -> nil end

    next_fun = fn position ->
      case position do
        :end_stream ->
          {:halt, nil}

        current_position ->
          get_opts = Keyword.put(opts, :position, current_position)
          records = database.get(session, stream_name, get_opts)
          last_record = List.last(records)
          next_position = get_next_position(last_record, stream_name)
          {records, next_position}
      end
    end

    stream = Stream.resource(start_fun, next_fun, after_fun)

    if is_nil(fun),
      do: stream,
      else: Enum.reduce(stream, nil, fun)
  end

  @spec write(
          session :: term(),
          database :: module(),
          messages :: struct() | [struct()],
          stream_name :: String.t(),
          opts :: [write_option()]
        ) :: non_neg_integer()
  def write(session, database, message, stream_name)
      when not is_list(message) do
    write(session, database, [message], stream_name, [])
  end

  def write(session, database, messages, stream_name) when is_list(messages) do
    write(session, database, messages, stream_name, [])
  end

  def write(session, database, message, stream_name, opts)
      when not is_list(message) do
    write(session, database, [message], stream_name, opts)
  end

  def write(session, database, messages, stream_name, opts)
      when is_list(messages) do
    messages
    |> Stream.with_index()
    |> Enum.reduce(nil, fn {message, index}, _ ->
      message_data = Transform.write(message)

      expected_version = Keyword.get(opts, :expected_version)

      expected_version =
        if is_nil(expected_version) do
          nil
        else
          expected_version
          |> ExpectedVersion.canonize()
          |> Kernel.+(index)
        end

      database.put(session, message_data, stream_name,
        expected_version: expected_version
      )
    end)
  end

  @spec write_initial(
          session :: term(),
          database :: module(),
          message :: struct(),
          stream_name :: String.t()
        ) :: non_neg_integer()
  def write_initial(session, database, message, stream_name)
      when not is_list(message) do
    write(session, database, message, stream_name, expected_version: :no_stream)
  end

  @spec get_next_position(
          message_data :: %Read{} | nil,
          stream_name :: String.t()
        ) :: non_neg_integer() | :end_stream
  defp get_next_position(nil, _stream_name), do: :end_stream

  defp get_next_position(message_data, stream_name) do
    if StreamName.category?(stream_name) do
      message_data.global_position + 1
    else
      message_data.position + 1
    end
  end

  defmacro __using__(database: database) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      def read(session, stream_name, opts \\ [], fun \\ nil) do
        database = unquote(database)
        unquote(__MODULE__).read(session, database, stream_name, opts, fun)
      end

      def write(session, message_or_messages, stream_name, opts \\ []) do
        database = unquote(database)

        unquote(__MODULE__).write(
          session,
          database,
          message_or_messages,
          stream_name,
          opts
        )
      end

      def write_initial(session, message, stream_name) do
        database = unquote(database)

        unquote(__MODULE__).write_initial(
          session,
          database,
          message,
          stream_name
        )
      end

      defoverridable unquote(__MODULE__)
      defoverridable read: 2, read: 3, write: 3
    end
  end
end
