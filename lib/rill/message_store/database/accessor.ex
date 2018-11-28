defmodule Rill.MessageStore.Database.Accessor do
  alias Rill.MessageStore.Database
  alias Rill.MessageStore.MessageData.Read
  alias Rill.MessageStore.MessageData.Write

  @callback get(
              stream_name :: String.t(),
              opts :: [Database.get_opts()]
            ) :: [%Read{}]

  @callback get_last(stream_name :: String.t()) :: %Read{} | nil

  @callback put(
              msg :: %Write{},
              stream_name :: String.t(),
              opts :: [Database.put_opts()]
            ) :: non_neg_integer()
end
