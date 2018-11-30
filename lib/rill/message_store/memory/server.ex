defmodule Rill.MessageStore.Memory.Server do
  use GenServer
  alias Rill.MessageStore.MessageData.Read
  alias Rill.MessageStore.StreamName

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

  def start_link(name) do
    GenServer.start_link(__MODULE__, nil, name: name)
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
    ) do
      {:reply, {:ok, msg.position}, [msg | state]}
    else
      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:get, stream_name, opts}, _from, state) do
    messages =
      if StreamName.category?(stream_name) do
        handle_opt_global_position(messages_by_stream(stream_name, state), opts)
      else
        handle_opt_position(messages_by_stream(stream_name, state), opts)
      end

    {:reply, {:ok, messages}, state}
  end

  @impl true
  def handle_call({:get_last, stream_name}, _from, state) do
    {:reply, {:ok, List.last(messages_by_stream(stream_name, state))}, state}
  end

  defp set_msg_properties(msg, stream_name, state) do
    new_msg =
      msg
      |> Map.put(:id, Ecto.UUID.generate())
      |> Map.put(:global_position, length(state) + 1)
      |> Map.put(:position, count_messages_for_stream_name(stream_name, state))
      |> Map.put(:stream_name, stream_name)
      |> Map.put(:time, NaiveDateTime.to_iso8601(NaiveDateTime.utc_now()))
      |> Rill.Messaging.Message.Transform.read()
      |> Read.build()

    {:ok, new_msg}
  end

  defp count_messages_for_stream_name(stream_name, state) do
    state |> Enum.count(fn x -> x.stream_name == stream_name end)
  end

  defp handle_opt_expected_version(msg, opts) do
    case Keyword.get(opts, :expected_version) do
      nil ->
        :ok

      expected_version ->
        if msg.position - 1 != expected_version do
          {:error, :concurrency_issue}
        else
          :ok
        end
    end
  end

  def handle_opt_reply_stream_name(msg, opts) do
    case Keyword.get(opts, :reply_stream_name) do
      nil ->
        {:ok, msg}

      reply_stream_name ->
        metadata =
          case Map.fetch(msg, :metadata) do
            {:ok, nil} -> %{}
            {:ok, data} when is_map(data) -> data
          end

        metadata = Map.put(metadata, :reply_stream_name, reply_stream_name)
        {:ok, Map.put(msg, :metadata, metadata)}
    end
  end

  def handle_opt_position(messages, opts) do
    case Keyword.get(opts, :position) do
      nil ->
        messages

      position when position > -1 ->
        {_, messages_from_position} = Enum.split(messages, position)
        messages_from_position
    end
  end

  def handle_opt_global_position(messages, opts) do
    case Keyword.get(opts, :position) do
      nil ->
        messages

      position when position > -1 ->
        messages
        |> Enum.reverse()
        |> Enum.filter(&(&1.global_position >= position))
    end
  end

  defp messages_by_stream(stream_name, state) do
    state
    |> Enum.reverse()
    |> Enum.filter(fn x ->
      stream_match?(x.metadata.stream_name, stream_name)
    end)
  end

  defp stream_match?(message_stream_name, expected_stream_name) do
    if StreamName.category?(expected_stream_name) do
      StreamName.get_category(message_stream_name) == expected_stream_name
    else
      expected_stream_name == message_stream_name
    end
  end
end
