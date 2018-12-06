defmodule Rill.MessageStore.Reader do
  alias Rill.MessageStore
  alias Rill.Session

  @spec handle(
          session :: Session.t(),
          stream_name :: String.t(),
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
    repeat_times = Range.new(1, times)

    Enum.each(repeat_times, fn _ ->
      session
      |> MessageStore.read(stream_name, opts)
      |> Enum.each(fn message -> handler.handle(session, message) end)
    end)

    session
  end
end
