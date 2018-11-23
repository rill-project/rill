defmodule Rill.MessageStore.MessageData.Write do
  defstruct [:id, :type, :data, :metadata]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          data: map(),
          metadata: map()
        }

  @spec build(data :: map()) :: %__MODULE__{}
  def build(%{} = data) do
    {write, _} = MapCopy.copy_existing(%__MODULE__{}, data)
    write
  end
end
