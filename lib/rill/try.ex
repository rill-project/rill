defmodule Rill.Try do
  defmacro try(error, do: block) do
    quote do
      try do
        unquote(block)
      rescue
        unquote(error) -> nil
      end
    end
  end

  defmacro try_version(do: block) do
    quote do
      try do
        unquote(block)
      rescue
        Rill.MessageStore.ExpectedVersion.Error -> nil
      end
    end
  end
end
