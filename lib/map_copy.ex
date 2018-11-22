defmodule MapCopy do
  @doc """
  Copies `data` over `receiver`, only the fields that are in common. The
  returned value is a tuple with first value being the updated receiver and
  the second value being a list of keys copied over
  """
  @spec copy_existing(receiver :: map() | struct(), data :: map() | struct()) ::
          {map() | struct(), list()}
  def copy_existing(%{} = receiver, %{__struct__: _} = struct) do
    map = Map.from_struct(struct)
    copy_existing(receiver, map)
  end

  def copy_existing(%{} = receiver, %{} = data) do
    receiver_keys = Map.keys(receiver)
    filtered_data = Map.take(data, receiver_keys)
    copying_keys = Map.keys(filtered_data)

    new_receiver = Map.merge(receiver, filtered_data)
    {new_receiver, copying_keys}
  end
end
