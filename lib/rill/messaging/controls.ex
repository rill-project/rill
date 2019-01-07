defmodule Rill.Messaging.Controls do
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
    end
  end
end
