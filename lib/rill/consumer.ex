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
            condition: nil,
            session: nil

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
          condition: nil | term(),
          session: nil | Rill.Session.t()
        }

  @spec dispatch(state :: t(), pid :: pid()) :: t()
  def dispatch(%__MODULE__{messages: []} = state, pid) do
    GenServer.cast(pid, :fetch)
    state
  end

  def dispatch(
        %__MODULE__{messages: [_ | _] = messages_data, session: session} =
          state,
        pid
      ) do
    handlers = state.handlers
    [message_data | new_messages_data] = messages_data

    Enum.each(handlers, fn handler ->
      Handler.handle(session, handler, message_data)
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
    session = state.session

    opts = [
      position: state.position,
      batch_size: state.batch_size,
      condition: state.condition
    ]

    case session.database.get(session, state.stream_name, opts) do
      [] ->
        state

      new_messages ->
        GenServer.cast(pid, :dispatch)
        Map.put(state, :messages, new_messages)
    end
  end

  defdelegate start_link(initial_state, opts \\ []), to: Rill.Consumer.Server

  @doc """
  - `:handlers`
  - `:identifier`
  - `:stream_name`
  - `:poll_interval_milliseconds`
  - `:batch_size`
  - `:session`
  - `:condition`
  """
  def child_spec(opts, genserver_opts \\ []) do
    handlers = Keyword.fetch!(opts, :handlers)
    identifier = Keyword.fetch!(opts, :identifier)
    stream_name = Keyword.fetch!(opts, :stream_name)
    session = Keyword.fetch!(opts, :session)

    poll_interval_milliseconds =
      Keyword.get(
        opts,
        :poll_interval_milliseconds,
        Defaults.poll_interval_milliseconds()
      )

    batch_size = Keyword.get(opts, :batch_size, Defaults.batch_size())
    condition = Keyword.get(opts, :condition)

    initial_state = %__MODULE__{
      handlers: handlers,
      identifier: identifier,
      stream_name: stream_name,
      session: session,
      poll_interval_milliseconds: poll_interval_milliseconds,
      batch_size: batch_size,
      condition: condition
    }

    %{
      id: __MODULE__.Server,
      start: {__MODULE__.Server, :start_link, [initial_state, genserver_opts]}
    }
  end
end
