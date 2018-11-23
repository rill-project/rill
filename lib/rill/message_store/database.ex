defmodule Rill.MessageStore.Database do
  alias Rill.MessageData.Read
  alias Rill.MessageStore.ExpectedVersion

  @type get_option_position :: {:position, non_neg_integer()}
  @type get_option_batch_size :: {:batch_size, pos_integer()}
  @type get_option_condition :: {:condition, String.t()}
  @type get_opts :: [
          get_option_position(),
          get_option_batch_size(),
          get_option_condition()
        ]
  @callback get(
              session :: term(),
              stream_name :: String.t(),
              opts :: get_opts()
            ) :: [%Read{}]

  @type put_option_expected_version :: {:expected_version, ExpectedVersion.t()}
  @type put_option_identifier_get :: {:identifier_get, (() -> String.t())}
  @type put_opts :: [
          put_option_expected_version(),
          put_option_identifier_get()
        ]
  @callback put(session :: term(), opts :: put_opts()) :: %Write{}
end
