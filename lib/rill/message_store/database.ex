defmodule Rill.MessageStore.Database do
  alias Rill.MessageStore.MessageData.Read
  alias Rill.MessageStore.MessageData.Write
  alias Rill.MessageStore.ExpectedVersion
  alias Rill.Session
  alias Rill.MessageStore.StreamName

  @type get_opts ::
          {:position, non_neg_integer()}
          | {:batch_size, pos_integer()}
          | {:condition, term()}
  @callback get(
              session :: Session.t(),
              stream_name :: StreamName.t(),
              opts :: [get_opts()]
            ) :: [%Read{}]

  @callback get_last(
              session :: Session.t(),
              stream_name :: StreamName.t()
            ) :: %Read{} | nil

  @type put_opts ::
          {:expected_version, ExpectedVersion.t()}
          | {:identifier_get, (() -> String.t()) | nil}
  @callback put(
              session :: Session.t(),
              msg :: %Write{},
              stream_name :: StreamName.t(),
              opts :: [put_opts()]
            ) :: non_neg_integer()
end
