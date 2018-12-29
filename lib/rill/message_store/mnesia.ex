defmodule Rill.MessageStore.Mnesia do
  use Rill.MessageStore

  alias Rill.Session
  alias Rill.MessageStore.StreamName
  alias Rill.MessageStore.ExpectedVersion
  alias Rill.MessageStore.Mnesia.Repo

  @spec start() :: no_return()
  def start do
    Repo.start()
    Repo.create()
  end

  @spec truncate(session :: Session.t()) :: no_return()
  def truncate(session) do
    namespace = Session.get_config(session, :namespace)
    Repo.truncate(namespace)
  end

  @spec info(session :: Session.t()) :: no_return()
  def info(session) do
    namespace = Session.get_config(session, :namespace)
    records = Repo.info(namespace)

    IO.puts("INFO for Mnesia namespace: #{namespace}")

    records
    |> Stream.map(fn record ->
      [_id, stream_name, type, position | _args] = record
      "#{stream_name}/#{position} - #{type}"
    end)
    |> Enum.each(&IO.puts/1)
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
      Repo.transaction(
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
