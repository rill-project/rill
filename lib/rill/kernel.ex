defmodule Rill.Kernel do
  defmacro __using__(_opts \\ []) do
    quote do
      require Scribble
      alias Scribble, as: Log
    end
  end
end
