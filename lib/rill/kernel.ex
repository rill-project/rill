defmodule Rill.Kernel do
  defmacro __using__(_opts \\ []) do
    quote do
      require Logger
      alias Logger, as: Log
    end
  end
end
