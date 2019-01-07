defmodule Rill.EntityStore.Controls do
  defmodule Store.Example do
    use Rill.EntityProjection.Controls

    @category_name "someEntity"

    use Rill, [
      :store,
      entity: Entity.example(),
      category: @category_name,
      projection: Projection.Example
    ]

    def category_name, do: @category_name
  end

  defmacro __using__(_opts \\ []) do
    quote do
      use Rill.EntityProjection.Controls
      alias unquote(__MODULE__).Store
    end
  end
end
