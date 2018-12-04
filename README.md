# Rill

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rill` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rill, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/rill](https://hexdocs.pm/rill).

## Examples

### Memory

```elixir

defmodule Foo do
  use Rill.Messaging.Message
  defmessage([:name, :age])
end

defmodule Repo do
  use Ecto.Repo,
    otp_app: :rill,
    adapter: Ecto.Adapters.Postgres

  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end

defmodule MessageStore do
  use Rill.MessageStore.Ecto.Postgres, repo: Repo
end

defmodule Run do
  def run do
    Repo.start_link(name: Repo)
  end
end

Run.run()
tmp = %Foo{name: "foo", age: 213}
MessageStore.write(tmp, "foo-123")
MessageStore.read("foo-123", position: 0, batch_size: 1)|>Enum.map(fn m -> m end)

defmodule Foo do
  use Rill.Messaging.Message
  defmessage([:name, :age])
end

defmodule MessageStore do
  use Rill.MessageStore.Memory, namespace: NameSpace
end

defmodule Run do
  def run do
    Rill.MessageStore.Memory.Server.start_link(nil, name: NameSpace)
  end
end
```

### Everything

```elixir

defmodule Person do
  defstruct [:name, :age]
end

defmodule Renamed do
  use Rill, :message
  defmessage([:name])
end

defmodule PersonProjection do
  use Rill, :projection

  @impl Rill.EntityProjection
  deftranslate apply(%Renamed{} = renamed, person) do
    Map.put(person, :name, renamed.name)
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

defmodule Store do
  use Rill.EntityStore,
    entity: %Person{},
    category: "person",
    projection: PersonProjection
end

defmodule Handler do
  use Rill, :handler

  @impl Rill.Messaging.Handler
  deftranslate handle(%Renamed{} = renamed, _session) do
    IO.inspect(renamed)
    IO.puts("hello")
  end
end

defmodule Run do
  def run do
    {:ok, pid1} = Repo.start_link(name: Repo)

    session = Rill.MessageStore.Ecto.Postgres.Session.new(Repo)

    # renamed = %Renamed{name: "foo1234r"}
    # MessageStore.write(renamed, "person-123")
    # Store.get(session, "123", include: [:version])
    # Rill.Messaging.Handler(Handler, MessageStore.read("person-123"))
    # {:ok, pid2} = Consumer.start_link()
    # IO.inspect({pid1, pid2})
    # Process.unlink(pid1)
    # Process.unlink(pid2)

    # :timer.sleep(1500)
    # Process.exit(pid2, "timetogo")
    Supervisor.start_link(
      [
        {Rill.Consumer,
         [
           handlers: [Handler],
           stream_name: "person",
           identifier: "personIdentifier",
           session: session,
           poll_interval_milliseconds: 10000,
           batch_size: 1
         ]}
      ],
      strategy: :one_for_one
    )
  end

  def run2 do
    {:ok, pid1} = Rill.MessageStore.Memory.Server.start_link(name: :foo)

    session = Rill.MessageStore.Memory.Session.new(:foo)

    renamed = %Renamed{name: "foo1234r"}
    Rill.MessageStore.write(session, renamed, "person-123")
    Store.get(session, "123", include: [:version])
  end
end
```
