defmodule Rill.Messaging.Message.Transform do
  alias Rill.Messaging.Message.Transformable
  alias Rill.MessageStore.MessageData.Write

  @spec write(msg :: struct()) :: %Write{}
  defdelegate write(msg), to: Transformable

  def read(%{__struct__: _} = message_data) do
    message_data
    |> Map.from_struct()
    |> read()
  end

  @spec read(data :: map()) :: map()
  def read(%{} = data) do
    metadata = data[:metadata] || %{}

    metadata
    |> Map.put(:stream_name, data[:stream_name])
    |> Map.put(:position, data[:position])
    |> Map.put(:global_position, data[:global_position])
    |> Map.put(:time, data[:time])

    Map.put(data, :metadata, metadata)
  end
end

defmodule Repo do
  use Ecto.Repo,
    otp_app: :rill,
    adapter: Ecto.Adapters.Postgres

  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end

defmodule Foo do
  use Rill.Messaging.Message

  defmessage([:name, :age])
end

defmodule Runme do
  def run(expected_version \\ nil) do
    Repo.start_link(name: Repo)
    tmp = %Foo{name: "Fra", age: 30}

    tmp = Rill.Messaging.Message.Transform.write(tmp)

    Rill.MessageStore.Ecto.Postgres.Database.put(Repo, tmp, "cacca-123",
      expected_version: expected_version
    )
  end
end
