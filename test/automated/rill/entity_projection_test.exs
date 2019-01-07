defmodule Rill.EntityProjectionTest do
  use AsyncCase

  defmodule Person do
    defstruct name: "", age: 0
  end

  defmodule Renamed do
    use Rill, :message
    defmessage([:name])
  end

  defmodule Aged do
    use Rill, :message
    defmessage([:amount])
  end

  defmodule Projection do
    use Rill, :projection

    @impl true
    deftranslate apply(%Renamed{} = renamed, person) do
      Map.put(person, :name, renamed.name)
    end

    @impl true
    deftranslate apply(%Aged{} = aged, person) do
      age = person.age + aged.amount
      Map.put(person, :age, age)
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

  describe "with multiple events" do
    test "applies changes to entity" do
      person = %Person{name: "Joe"}
      renamed = %Renamed{name: "Ben"}
      aged = %Aged{amount: 3}

      new_person = EntityProjection.apply(Projection, person, [renamed, aged])

      assert new_person.name == "Ben" && new_person.age == 3
    end
  end
end
