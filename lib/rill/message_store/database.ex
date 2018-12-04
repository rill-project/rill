defmodule Rill.MessageStore.Database do
  alias Rill.MessageStore.MessageData.Read
  alias Rill.MessageStore.MessageData.Write
  alias Rill.MessageStore.ExpectedVersion
  alias Rill.Session

  @type get_opts ::
          {:position, non_neg_integer()}
          | {:batch_size, pos_integer()}
          | {:condition, term()}
  @callback get(
              session :: Session.t(),
              stream_name :: String.t(),
              opts :: [get_opts()]
            ) :: [%Read{}]

  @callback get_last(session :: Session.t(), stream_name :: String.t()) ::
              %Read{} | nil

  @type put_opts ::
          {:expected_version, ExpectedVersion.t()}
          | {:identifier_get, (() -> String.t()) | nil}
  @callback put(
              session :: Session.t(),
              msg :: %Write{},
              stream_name :: String.t(),
              opts :: [put_opts()]
            ) :: non_neg_integer()
end
