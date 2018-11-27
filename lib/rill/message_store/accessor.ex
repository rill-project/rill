defmodule Rill.MessageStore.Accessor do
  @callback read(
              stream_name :: String.t(),
              opts :: [Rill.MessageStore.Database.get_opts()],
              fun ::
                nil | (%Rill.MessageStore.MessageData.Read{}, term() -> term())
            ) :: Enumerable.t() | term()
  @callback write(
              message_or_messages :: struct() | [struct()],
              stream_name :: String.t(),
              opts :: [Rill.MessageStore.write_option()]
            ) :: non_neg_integer()
  @callback write_initial(
              message :: struct(),
              stream_name :: String.t()
            ) :: non_neg_integer()
end
