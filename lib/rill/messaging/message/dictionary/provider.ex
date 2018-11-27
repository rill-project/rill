defmodule Rill.Messaging.Message.Dictionary.Provider do
  @moduledoc false

  defmacro __before_compile__(_env) do
    quote location: :keep do
      @impl Rill.Messaging.Message.Dictionary
      def dictionary, do: @__rill_translate__
    end
  end
end
