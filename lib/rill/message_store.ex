defmodule Rill.MessageStore do
  @type read_option(
          {:position, non_neg_integer()}
          | {:batch_size, pos_integer()}
        )
  @doc """
  Returned enumerable must be a stream from the given position until the end
  of the stream
  """
  @callback read(
              session :: term(),
              stream_name :: String.t(),
              opts :: [read_option()]
            ) :: Enumerable.t()

  @type write_option(
          {:expected_version, Rill.MessageStore.ExpectedVersion.t()}
          | {:reply_stream_name, String.t() | nil}
        )
  @callback write(
              session :: term(),
              message :: struct(),
              stream_name :: String.t(),
              opts :: [write_option()]
            ) :: non_neg_integer()
  @callback write_initial(
              session :: term(),
              message :: struct(),
              stream_name :: String.t()
            ) :: non_neg_integer()
end
