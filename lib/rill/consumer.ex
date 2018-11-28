defmodule Rill.Consumer do
  defmodule Defaults do
    def poll_interval_milliseconds, do: 100
    def batch_size, do: 1000
    def position_update_interval, do: 100
  end

  defstruct position: 1,
            timer_ref: nil,
            messages: [],
            identifier: nil,
            handlers: [],
            stream_name: nil,
            poll_interval_milliseconds: Defaults.poll_interval_milliseconds(),
            batch_size: Defaults.batch_size(),
            reader: nil,
            condition: nil

  alias Rill.MessageStore.MessageData.Read
  alias Rill.Messaging.Handler

  @type t :: %__MODULE__{
          position: pos_integer(),
          timer_ref: nil | term(),
          messages: list(%Read{}),
          identifier: String.t(),
          handlers: list(module()),
          stream_name: String.t(),
          poll_interval_milliseconds: pos_integer(),
          batch_size: pos_integer(),
          reader: module(),
          condition: nil | term()
        }

  @spec dispatch(state :: t(), pid :: pid()) :: t()
  def dispatch(%__MODULE__{messages: []} = state, pid) do
    GenServer.cast(pid, :fetch)
    state
  end

  def dispatch(%__MODULE__{messages: [_ | _] = messages_data} = state, pid) do
    handlers = state.handlers
    [message_data | new_messages_data] = messages_data

    Enum.each(handlers, fn handler ->
      Handler.handle(handler, message_data)
    end)

    GenServer.cast(pid, :dispatch)

    state
    |> Map.put(:position, message_data.global_position + 1)
    |> Map.put(:messages, new_messages_data)
  end

  @spec listen(state :: t(), pid :: pid()) :: t()
  def listen(%__MODULE__{} = state, pid) do
    interval = state.poll_interval_milliseconds
    {:ok, ref} = :timer.send_interval(interval, pid, :reminder)

    GenServer.cast(pid, :fetch)

    Map.put(state, :timer_ref, ref)
  end

  @spec unlisten(state :: t()) :: t()
  def unlisten(%__MODULE__{} = state) do
    ref = state.timer_ref
    :timer.cancel(ref)

    Map.put(state, :timer_ref, nil)
  end

  @spec fetch(state :: t(), pid :: pid()) :: {:noreply, t()}
  def fetch(%__MODULE__{messages: [_ | _]} = state, _pid), do: state

  def fetch(%__MODULE__{messages: []} = state, pid) do
    opts = [
      position: state.position,
      batch_size: state.batch_size,
      condition: state.condition
    ]

    case state.reader.get(state.stream_name, opts) do
      [] ->
        state

      new_messages ->
        GenServer.cast(pid, :dispatch)
        Map.put(state, :messages, new_messages)
    end
  end

  defmacro __using__(opts \\ []) do
    quote location: :keep do
      use Rill.Consumer.Server, unquote(opts)
    end
  end
end
