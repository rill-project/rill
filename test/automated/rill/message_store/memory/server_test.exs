defmodule Rill.MessageStore.Memory.ServerTest do
  use AsyncCase 
  alias Rill.MessageStore.Memory.Database
  alias Rill.MessageStore.Memory.Server
  alias Rill.MessageStore.MessageData.Write 

  setup do
    session = :memory_server
    {:ok, _pid} = Server.start_link([], name: session)
    {:ok, %{session: session}}
  end

  @tag :current
  test "database put and gets against the in memory server", state do
    stream_name = "user-123"
    message = %Write{id: Ecto.UUID.generate, data: %{dave: "rules"}}

    Database.put(state.session, message, stream_name, expected_version: -1)
    |> IO.inspect

    Database.put(state.session, message, stream_name, expected_version: 0)
    |> IO.inspect

    Database.put(state.session, message, stream_name, reply_stream_name: "account-abc")
    |> IO.inspect

    Database.get_last(state.session, stream_name)
    |> IO.inspect label: "GET_LAST"

    :sys.get_state(state.session)
    |> IO.inspect label: "STATE"
  end
end
