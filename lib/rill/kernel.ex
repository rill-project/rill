defmodule Rill.Kernel do
  defmacro __using__(_opts \\ []) do
    quote do
      require Rill.Logger
      alias Rill.Logger, as: Log
    end
  end
end
