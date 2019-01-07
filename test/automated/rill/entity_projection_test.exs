defmodule Rill.EntityProjectionTest do
  use AsyncCase

  defmodule Person do
    defstruct name: ""
  end

  defmodule Renamed do
    use Rill, :message
    defmessage([:name])
  end

  defmodule Projection do
    use Rill, :projection

    @impl true
    deftranslate apply(%Renamed{} = renamed, person) do
      Map.put(person, :name, renamed.name)
    end
  end

  alias Rill.EntityProjection

  describe "with single event" do
    test "applies changes to entity" do
      person = %Person{name: "Joe"}
      renamed = %Renamed{name: "Ben"}

      new_person = EntityProjection.apply(Projection, person, renamed)

      assert new_person.name == "Ben"
    end
  end
end
