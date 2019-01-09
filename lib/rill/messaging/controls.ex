defmodule Rill.Messaging.Controls do
  defmodule Category do
    def example(category, true) do
      "#{category}#{UUID.uuid4()}XX"
    end

    def example(category, false) do
      to_string(category)
    end

    def example(category) do
      example(category, true)
    end

    def example do
      example("", true)
    end
  end

  defmodule MessageData.SomeMessage do
    use Rill, :message
    defstruct [:some_attribute]
    def example, do: %__MODULE__{some_attribute: "foo"}
  end

  defmodule MessageData.SomeOtherMessage do
    use Rill, :message
    defstruct [:some_other_attribute]
    def example, do: %__MODULE__{some_other_attribute: 123}
  end

  defmacro __using__(_opts \\ []) do
    quote do
      alias unquote(__MODULE__).MessageData
      alias unquote(__MODULE__).Category
    end
  end
end
