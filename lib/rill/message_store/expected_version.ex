defmodule Rill.MessageStore.ExpectedVersion do
  defmodule Error do
    defexception [:message]
  end

  @type t :: :no_stream | nil | non_neg_integer()
  @type canonical :: -1 | non_neg_integer()

  @spec canonize(expected_version :: t()) :: canonical()
  def canonize(nil), do: nil
  def canonize(:no_stream), do: NoStream.version()
  def canonize(expected_version), do: expected_version
end
