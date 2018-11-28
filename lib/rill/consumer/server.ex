defmodule Rill.Consumer.Server do
  @doc """
  - `:handlers`
  - `:identifier`
  - `:stream_name`
  - `:poll_interval_milliseconds`
  - `:batch_size`
  - `:reader`
  - `:condition`
  """
  defmacro __using__(opts \\ []) do
    handlers = Keyword.fetch!(opts, :handlers)
    identifier = Keyword.get(opts, :identifier) || to_string(__CALLER__.module)
    stream_name = Keyword.fetch!(opts, :stream_name)

    poll_interval_milliseconds =
      Keyword.get(
        opts,
        :poll_interval_milliseconds,
        Rill.Consumer.Defaults.poll_interval_milliseconds()
      )

    batch_size =
      Keyword.get(opts, :batch_size, Rill.Consumer.Defaults.batch_size())

    reader = Keyword.fetch!(opts, :reader)
    condition = Keyword.get(opts, :condition)

    quote location: :keep do
      use GenServer

      def child_spec(args \\ []) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [Map.new(args)]}
        }
      end

      def start_link(merge_state \\ %{}, opts \\ []) do
        GenServer.start_link(__MODULE__, merge_state, opts)
      end

      @impl GenServer
      def init(merge_state \\ %{}) do
        state =
          %Rill.Consumer{}
          |> Map.put(:identifier, unquote(identifier))
          |> Map.put(:handlers, unquote(handlers))
          |> Map.put(:stream_name, unquote(stream_name))
          |> Map.put(
            :poll_interval_milliseconds,
            unquote(poll_interval_milliseconds)
          )
          |> Map.put(:batch_size, unquote(batch_size))
          |> Map.put(:reader, unquote(reader))
          |> Map.put(:condition, unquote(condition))
          |> Map.merge(merge_state)

        state = Rill.Consumer.listen(state, self())

        {:ok, state}
      end

      @impl GenServer
      def handle_cast(:fetch, %Rill.Consumer{} = state) do
        state = Rill.Consumer.fetch(state, self())
        {:noreply, state}
      end

      @impl GenServer
      def handle_cast(:dispatch, %Rill.Consumer{} = state) do
        state = Rill.Consumer.dispatch(state, self())
        {:noreply, state}
      end

      @impl GenServer
      def handle_info(:reminder, %Rill.Consumer{} = state) do
        GenServer.cast(self(), :fetch)
        {:noreply, state}
      end
    end
  end
end
