defmodule Rill.EntityStore.GetTest do
  use AsyncCase
  use Rill.EntityStore.Controls

  alias Rill.MessageStore.Mnesia.Session

  defp stream_id, do: "123"

  describe "with no events" do
    test "returns nil entity and nil version" do
      {session, _} = Session.rand()

      [nil, nil] = Store.Example.get(session, stream_id(), include: [:version])
    end
  end
end
