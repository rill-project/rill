defmodule Rill.MessageStore.MessageData.Write do
  defstruct [:id, :type, :data, :metadata]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          data: map(),
          metadata: map()
        }
end
