defmodule Rill.MessageStore.Ecto.Postgres do
  @database Rill.MessageStore.Ecto.Postgres.Database
  use Rill.MessageStore, database: @database

  alias Rill.MessageStore.Ecto.Postgres.Session

  @type transaction_timeout_option ::
          {:transaction_timeout, :infinity | pos_integer()}
  @spec write(
          session :: term(),
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

    repo = Session.get(session)

    repo.transaction(
      fn ->
        Rill.MessageStore.write(
          repo,
          @database,
          message_or_messages,
          stream_name,
          opts
        )
      end,
      transaction_opts
    )
  end

  defmacro __using__(repo: repo) do
    quote location: :keep do
      @spec read(
              stream_name :: String.t(),
              opts :: [Rill.MessageStore.Database.get_opts()],
              fun ::
                nil | (%Rill.MessageStore.MessageData.Read{}, term() -> term())
            ) :: Enumerable.t() | term()
      def read(stream_name, opts \\ [], fun \\ nil) do
        repo = unquote(repo)
        unquote(__MODULE__).read(repo, stream_name, opts, fun)
      end

      @spec write(
              message_or_messages :: struct() | [struct()],
              stream_name :: String.t(),
              opts :: [Rill.MessageStore.write_option()]
            ) :: non_neg_integer()
      def write(message_or_messages, stream_name, opts \\ []) do
        repo = unquote(repo)
        unquote(__MODULE__).write(repo, message_or_messages, stream_name, opts)
      end

      @spec write_initial(
              message :: struct(),
              stream_name :: String.t()
            ) :: non_neg_integer()
      def write_initial(message, stream_name) do
        repo = unquote(repo)
        unquote(__MODULE__).write_initial(repo, message, stream_name)
      end
    end
  end
end
