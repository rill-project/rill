defmodule Rill.MessageStore.Controls do
  defmodule StreamName do
    defmodule Id do
      def example, do: UUID.uuid4()
    end

    def example do
      id = Id.example()
      example(id)
    end

    def example(id) do
      category = Rill.Messaging.Controls.Category.example()
      example(id, category)
    end

    def example(id, category) do
      "#{category}-#{id}"
    end
  end

  defmacro __using__(_opts \\ []) do
    quote do
      alias unquote(__MODULE__).StreamName
    end
  end
end
