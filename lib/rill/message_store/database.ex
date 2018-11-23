defmodule Rill.MessageStore.Database do
  alias Rill.MessageStore.MessageData.Read
  alias Rill.MessageStore.MessageData.Write
  alias Rill.MessageStore.ExpectedVersion

  @type get_opts ::
          {:position, non_neg_integer()}
          | {:batch_size, pos_integer()}
          | {:condition, String.t()}
  @callback get(
              session :: term(),
              stream_name :: String.t(),
              opts :: [get_opts()]
            ) :: [%Read{}]

  @callback get_last(session :: term(), stream_name :: String.t()) ::
              %Read{} | nil

  @type put_opts ::
          {:expected_version, ExpectedVersion.t()}
          | {:identifier_get, (() -> String.t()) | nil}
  @callback put(
              session :: term(),
              msg :: %Write{},
              stream_name :: String.t(),
              opts :: [put_opts()]
            ) :: non_neg_integer()
end
