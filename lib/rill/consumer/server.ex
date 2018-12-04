defmodule Rill.Consumer.Server do
  use GenServer

  alias Rill.Consumer

  def start_link(%Consumer{} = initial_state, opts \\ []) do
    GenServer.start_link(__MODULE__, initial_state, opts)
  end

  @impl GenServer
  def init(%Consumer{} = initial_state) do
    state = initial_state

    Process.flag(:trap_exit, true)
    state = Consumer.listen(state, self())

    {:ok, state}
  end

  @impl GenServer
  def handle_cast(:fetch, %Consumer{} = state) do
    state = Consumer.fetch(state, self())
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:dispatch, %Consumer{} = state) do
    state = Consumer.dispatch(state, self())
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:reminder, %Consumer{} = state) do
    GenServer.cast(self(), :fetch)
    {:noreply, state}
  end
end
