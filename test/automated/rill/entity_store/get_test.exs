defmodule Rill.EntityStore.GetTest do
  use AsyncCase
  use Rill.EntityStore.Controls

  alias Rill.EntityStore
  alias Rill.MessageStore
  alias Rill.MessageStore.Mnesia.Session

  defp category_name, do: Store.Example.category_name()
  defp stream_id, do: "123"

  defp stream_name(id) do
    category_name() <> "-#{id}"
  end

  defp stream_name, do: stream_name(stream_id())

  describe "with no events" do
    test "returns nil entity and nil version" do
      {session, _} = Session.rand()
      msg = MessageData.SomeMessage.example()

      [nil, nil] = Store.Example.get(session, stream_id(), include: [:version])
    end
  end
end
