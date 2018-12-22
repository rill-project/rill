defmodule Rill.MessageStore.Reader do
  use Rill.Kernel
  alias Rill.MessageStore
  alias Rill.Session
  alias Rill.MessageStore.StreamName

  @spec handle(
          session :: Session.t(),
          stream_name :: StreamName.t(),
          handler :: module(),
          times :: pos_integer(),
          opts :: [MessageStore.read_option()]
        ) :: Session.t()
  def handle(session, stream_name, handler),
    do: handle(session, stream_name, handler, 1, [])

  def handle(session, stream_name, handler, opts) when is_list(opts),
    do: handle(session, stream_name, handler, 1, opts)

  def handle(session, stream_name, handler, times) when is_integer(times),
    do: handle(session, stream_name, handler, times, [])

  def handle(%Session{} = session, stream_name, handler, times, opts) do
    Log.trace(fn ->
      "Handling (Stream Name: #{stream_name}, Handler: #{handler}, Times: #{
        times
      })"
    end)

    repeat_times = Range.new(1, times)

    Enum.each(repeat_times, fn _ ->
      session
      |> MessageStore.read(stream_name, opts)
      |> Enum.each(fn message -> handler.handle(session, message) end)
    end)

    Log.info(fn ->
      "Handled (Stream Name: #{stream_name}, Handler: #{handler}, Times: #{
        times
      })"
    end)

    session
  end
end
