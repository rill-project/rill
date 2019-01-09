defmodule Rill.EntityProjectionTest do
  use AsyncCase
  use Rill.EntityProjection.Controls

  alias Rill.EntityProjection

  describe "with single event" do
    test "applies changes to entity" do
      entity = Entity.example()
      msg = MessageData.SomeMessage.example()

      new_entity = EntityProjection.apply(Projection.Example, entity, msg)

      assert new_entity.some_attribute == msg.some_attribute
    end
  end

  describe "with multiple events" do
    test "applies changes to entity" do
      entity = Entity.example()
      msg = MessageData.SomeMessage.example()
      other_msg = MessageData.SomeOtherMessage.example()
      msgs = [msg, other_msg]

      new_entity = EntityProjection.apply(Projection.Example, entity, msgs)

      assert new_entity.some_attribute == msg.some_attribute
      assert new_entity.some_other_attribute == other_msg.some_other_attribute
    end
  end
end
