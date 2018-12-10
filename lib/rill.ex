defmodule Rill do
  def message do
    quote do
      use Rill.Messaging.Message
    end
  end

  def projection do
    quote do
      use Rill.EntityProjection
    end
  end

  def handler do
    quote do
      use Rill.Messaging.Handler
      alias Rill.MessageStore
      alias Rill.Messaging.Message

      require Rill
      import Rill, only: [try_version: 1]

      import Rill.MessageStore.StreamName,
        only: [stream_name: 1, stream_name: 2, stream_name: 3]
    end
  end

  def store(opts) do
    quote do
      use Rill.EntityStore, unquote(opts)
    end
  end

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

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__([which]) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__([which | opts])
           when is_atom(which) and is_list(which_opts) do
    apply(__MODULE__, which, [opts])
  end
end
