defmodule Rill.EntityProjection.Controls do
  defmodule Entity do
    defstruct [:some_attribute, :some_other_attribute]

    def example, do: %__MODULE__{}
  end

  defmodule Projection.Example do
    use Rill, :projection
    use Rill.Messaging.Controls

    @impl Rill.EntityProjection
    def apply(%MessageData.SomeMessage{} = msg, entity) do
      Map.put(entity, :some_attribute, msg.some_attribute)
    end

    @impl Rill.EntityProjection
    def apply(%MessageData.SomeOtherMessage{} = msg, entity) do
      Map.put(entity, :some_other_attribute, msg.some_other_attribute)
    end
  end

  defmacro __using__(_opts \\ []) do
    quote do
      alias unquote(__MODULE__).Entity
      alias unquote(__MODULE__).Projection
      use Rill.Messaging.Controls
    end
  end
end
