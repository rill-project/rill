defmodule Rill.MessageStore.Base do
  alias Rill.Messaging.Message.Transform
  alias Rill.MessageStore.MessageData.Read
  alias Rill.MessageStore.StreamName
  alias Rill.MessageStore.ExpectedVersion
  alias Rill.Session

  @spec read(
          session :: Session.t(),
          stream_name :: String.t(),
          opts :: [Rill.MessageStore.read_option()],
          fun :: nil | (%Read{}, term() -> term())
        ) :: Enumerable.t() | term()
  def read(session, stream_name, opts \\ [], fun \\ nil) do
    database = session.database
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
          session :: Session.t(),
          messages :: struct() | [struct()],
          stream_name :: String.t(),
          opts :: [Rill.MessageStore.write_option()]
        ) :: non_neg_integer()
  def write(session, message, stream_name)
      when not is_list(message) do
    write(session, [message], stream_name, [])
  end

  def write(session, messages, stream_name) when is_list(messages) do
    write(session, messages, stream_name, [])
  end

  def write(session, message, stream_name, opts)
      when not is_list(message) do
    write(session, [message], stream_name, opts)
  end

  def write(session, messages, stream_name, opts)
      when is_list(messages) do
    database = session.database

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
          session :: Session.t(),
          message :: struct(),
          stream_name :: String.t()
        ) :: non_neg_integer()
  def write_initial(session, message, stream_name)
      when not is_list(message) do
    write(session, message, stream_name, expected_version: :no_stream)
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
end
