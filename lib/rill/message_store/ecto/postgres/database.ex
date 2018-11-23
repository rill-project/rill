defmodule Rill.MessageStore.Ecto.Postgres.Database do
  defmodule Defaults do
    @spec position() :: 0
    def position, do: 0
    @spec batch_size() :: 1000
    def batch_size, do: 1000
  end

  @behaviour Rill.MessageStore.Database

  alias Rill.MessageStore.Ecto.Postgres.Session
  alias Rill.MessageStore.StreamName

  @sql_params "$1::varchar, $2::bigint, $3::bigint, $4::varchar"

  @impl Rill.MessageStore.Database
  def get(session, stream_name, opts)
      when is_binary(stream_name) and is_list(opts) do
    repo = Session.get(session)
    condition = constrain_condition(opts[:condition])
    position = opts[:position] || Defaults.position()
    batch_size = opts[:batch_size] || Defaults.batch_size()
    sql = sql_command(stream_name)
    params = [stream_name, position, batch_size, condition]

    repo
    |> Ecto.Adapters.SQL.query!(sql, params)
    |> Map.fetch!(:rows)

    # |> convert()
    # TODO: Extract result
  end

  @spec constrain_condition(condition :: String.t() | nil) :: String.t() | nil
  def constrain_condition(nil), do: nil

  def constrain_condition(condition) when is_binary(condition) do
    "(#{condition})"
  end

  @spec sql_command(stream_name :: String.t()) :: String.t()
  def sql_command(stream_name) when is_binary(stream_name) do
    if StreamName.category?(stream_name) do
      "SELECT * FROM get_category_messages(#{@sql_params});"
    else
      "SELECT * FROM get_stream_messages(#{@sql_params});"
    end
  end
end
