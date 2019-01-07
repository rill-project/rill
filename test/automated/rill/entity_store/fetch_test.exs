defmodule Rill.EntityStore.FetchTest do
  use AsyncCase
  use Rill.EntityStore.Controls

  alias Rill.MessageStore
  alias Rill.MessageStore.Mnesia.Session

  defp category_name, do: Store.Example.category_name()
  defp stream_id, do: "123"

  defp stream_name(id) do
    category_name() <> "-#{id}"
  end

  defp stream_name, do: stream_name(stream_id())

  describe "with no events" do
    test "returns default entity and nil version" do
      {session, _} = Session.rand()

      [%Entity{}, nil] =
        Store.Example.fetch(session, stream_id(), include: [:version])
    end
  end

  describe "with some events" do
    test "returns entity projected with version 1" do
      {session, _} = Session.rand()
      msg = MessageData.SomeMessage.example()
      other_msg = MessageData.SomeOtherMessage.example()

      MessageStore.write(session, [msg, other_msg], stream_name())

      [entity, 1] =
        Store.Example.fetch(session, stream_id(), include: [:version])

      assert entity.some_attribute == msg.some_attribute
      assert entity.some_other_attribute == other_msg.some_other_attribute
    end
  end
end
