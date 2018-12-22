defmodule Rill.MessageStore.Mnesia do
  use Rill.MessageStore

  alias Rill.Session
  alias Rill.MessageStore.StreamName
  alias Rill.MessageStore.ExpectedVersion
  alias :mnesia, as: Mnesia
  alias Rill.MessageStore.Mnesia.Repo

  @spec start(namespace :: atom()) :: no_return()
  def start(namespace) do
    Mnesia.start()
    Repo.create(namespace)
  end

  @spec stop(namespace :: atom()) :: no_return()
  def stop(namespace) do
    Repo.delete(namespace)
  end

  @type transaction_retries_option :: {:transaction_retries, pos_integer()}
  @spec write(
          session :: Session.t(),
          message_or_messages :: struct() | [struct()],
          stream_name :: StreamName.t(),
          opts :: [
            Rill.MessageStore.write_option() | transaction_retries_option()
          ]
        ) :: non_neg_integer()
  @impl Rill.MessageStore
  def write(session, message_or_messages, stream_name, opts \\ []) do
    retries = opts[:transaction_retries] || 1

    opts = Keyword.delete(opts, :transaction_retries)

    result =
      Mnesia.transaction(
        fn ->
          Rill.MessageStore.Base.write(
            session,
            message_or_messages,
            stream_name,
            opts
          )
        end,
        retries
      )

    case result do
      {:atomic, position} -> position
      {:aborted, %ExpectedVersion.Error{} = error} -> raise error
      {:aborted, error} -> raise inspect(error)
      error -> raise inspect(error)
    end
  end
end
