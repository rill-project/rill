defmodule Rill.MessageStore.Memory.Server do
  use GenServer
  alias Rill.MessageStore.MessageData.Read

  @moduledoc """
  In memory message store. Read events are stored in a reversed ordered
  array.
  
  E.g. (state)

  [
    %Rill.MessageStore.MessageData.Read{
      data: %{},
      global_position: 2,
      id: "1413ac8e-69aa-4ded-b55c-67b2cc01783b",
      metadata: nil,
      position: 1,
      stream_name: "user-123",
      time: "2018-11-24T00:22:50.712897",
      type: nil
    },
    %Rill.MessageStore.MessageData.Read{
      data: %{},
      global_position: 1,
      id: "04fef10a-3774-4f15-aa68-7034fd9f758e",
      metadata: nil,
      position: 0,
      stream_name: "user-123",
      time: "2018-11-24T00:22:44.710048",
      type: nil
    }
  ]
  """

  def start_link(state, name: name) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl true
  def init(_starting_state) do
    {:ok, []}
  end

  @impl true
  def handle_call({:put, msg, stream_name, opts}, _from, state) do
    with(
      {:ok, msg} <- set_msg_properties(msg, stream_name, state),
      {:ok, msg} <- handle_opt_reply_stream_name(msg, opts),
      :ok <- handle_opt_expected_version(msg, opts)
    )
    do
      {:reply, {:ok, msg.position}, [msg | state]}
    else
      error -> 
        {:reply, error, state}
    end
  end

  defp set_msg_properties(msg, stream_name, state) do
    {
      :ok,
      Read.build(msg) 
      |> Map.put(:global_position, length(state) + 1)
      |> Map.put(:position, count_messages_for_stream_name(stream_name, state))
      |> Map.put(:stream_name, stream_name)
      |> Map.put(:time, NaiveDateTime.to_iso8601(NaiveDateTime.utc_now))
    }
  end

  defp count_messages_for_stream_name(stream_name, state) do
    state |> Enum.count(fn x -> x.stream_name == stream_name end )
  end

  defp handle_opt_expected_version(msg, opts) do
    case Keyword.get(opts, :expected_version) do
      nil -> :ok
      expected_version -> 
        if (msg.position - 1) != expected_version do
          {:error, :concurrency_issue}
        else
          :ok
        end
    end
  end
  def handle_opt_reply_stream_name(msg, opts) do
    case Keyword.get(opts, :reply_stream_name) do
      nil -> {:ok, msg}
      reply_stream_name -> 
        metadata = case Map.fetch(msg, :metadata) do
          {:ok, nil} -> %{}
          {:ok, data} when is_map(data) -> data
        end
        metadata = Map.put(metadata, :reply_stream_name, reply_stream_name)
        {:ok, Map.put(msg, :metadata, metadata)}
    end
  end

  @impl true
  def handle_call({:get, stream_name, opts}, _from, state) do
    messages = handle_opt_position(
      messages_by_stream(stream_name, state),
      opts
    )
    {:reply, {:ok, messages}, state}
  end

  def handle_opt_position(messages, opts) do
    case Keyword.get(opts, :position) do
      nil -> messages
      position when position > -1 -> 
        {_, messages_from_position} = Enum.split(messages, position)
        messages_from_position
    end
  end

  @impl true
  def handle_call({:get_last, stream_name}, _from, state) do
    {:reply, {:ok, List.last(messages_by_stream(stream_name, state))}, state}
  end

  defp messages_by_stream(stream_name, state) do
    state 
    |> Enum.reverse 
    |> Enum.filter(fn x -> x.stream_name == stream_name end)
  end
end
