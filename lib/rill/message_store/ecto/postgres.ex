defmodule Rill.MessageStore.Ecto.Postgres do
  use Rill.MessageStore

  alias Rill.Session

  @type transaction_timeout_option ::
          {:transaction_timeout, :infinity | pos_integer()}
  @spec write(
          session :: Session.t(),
          message_or_messages :: struct() | [struct()],
          stream_name :: String.t(),
          opts :: [
            Rill.MessageStore.write_option() | transaction_timeout_option()
          ]
        ) :: non_neg_integer()
  @impl Rill.MessageStore
  def write(session, message_or_messages, stream_name, opts \\ []) do
    transaction_opts =
      if Keyword.has_key?(opts, :transaction_timeout),
        do: [timeout: opts[:transaction_timeout]],
        else: []

    opts = Keyword.delete(opts, :transaction_timeout)
    repo = Session.get_config(session, :repo)

    repo.transaction(
      fn ->
        Rill.MessageStore.Base.write(
          session,
          message_or_messages,
          stream_name,
          opts
        )
      end,
      transaction_opts
    )
  end
end
