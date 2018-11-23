defmodule Rill.MessageStore.MessageData.Read do
  defstruct [
    :id,
    :type,
    :data,
    :metadata,
    :stream_name,
    :position,
    :global_position,
    :time
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          data: map(),
          metadata: map(),
          stream_name: String.t(),
          position: non_neg_integer(),
          global_position: pos_integer(),
          time: NaiveDateTime.t()
        }

  @spec build(data :: map()) :: %__MODULE__{}
  def build(%{} = data) do
    {read, _} = MapCopy.copy_existing(%__MODULE__{}, map)
    read
  end
end
