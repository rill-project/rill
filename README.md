# Rill

Translation of [Eventide Framework](https://eventide-project.org/) in Elixir.
Please refer to their [documentation](http://docs.eventide-project.org/)
for learning purposes or finding out arguments of some functions.

## Installation

Install via Hex:

```elixir
def deps do
  [
    {:rill, "~> 0.6.1"}
  ]
end
```

### Memory

To use the in-memory MessageStore, `Rill.MessageStore.Memory.Server` needs to be started and `Session` needs to be configured with the server pid (or name).

### Ecto.Postgres

To use the Ecto.Postgres MessageStore, `ecto` and `ecto_sql`, packages are
needed.

A Ruby installation is needed.

Following the steps for [Eventide Postgres Setup](http://docs.eventide-project.org/setup/postgres.html#eventide-for-postgres-setup),
up to [Create the Message Store Database](http://docs.eventide-project.org/setup/postgres.html#create-the-message-store-database)
(included), will ensure the database is correctly created.

A Repo module needs to be created, following these guidelines:

```elixir
defmodule MyRepo do
  use Ecto.Repo, otp_app: :your_app

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    # This part is entirely optional
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
```

The `Repo` module needs to be started and supplied to `Session` during
configuration.

## Getting Started

### Memory

```elixir
defmodule Renamed do
  use Rill, :message
  defmessage([:name])
end

{:ok, pid} = Rill.MessageStore.Memory.Server.start_link()
session = Rill.MessageStore.Memory.Session.new(pid)
message = %Renamed{name: "foo"}

Rill.MessageStore.write(session, message, "person")
```

### Postgres

```elixir
defmodule Renamed do
  use Rill, :message
  defmessage([:name])
end

{:ok, _pid} = MyRepo.start_link([name: MyRepo])
session = Rill.MessageStore.Ecto.Postgres.Session.new(MyRepo)
message = %Renamed{name: "foo"}

Rill.MessageStore.write(session, message, "person")
```

## Framework at a Glance

```elixir

defmodule Person do
  defstruct [:name, :age]
end

defmodule Renamed do
  use Rill, :message
  defmessage([:name])
end

defmodule Person.Projection do
  use Rill, :projection

  @impl Rill.EntityProjection
  deftranslate apply(%Renamed{} = renamed, person) do
    Map.put(person, :name, renamed.name)
  end
end

defmodule Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end

defmodule Store do
  use Rill, [
    :store,
    entity: %Person{},
    category: "person",
    projection: Person.Projection
  ]
end

defmodule Handler do
  use Rill, :handler

  @impl Rill.Messaging.Handler
  deftranslate handle(%Renamed{} = renamed, _session) do
    IO.inspect(renamed)
  end
end

defmodule Run do
  def run do
    {:ok, pid1} = Repo.start_link(name: Repo)

    session = Rill.MessageStore.Ecto.Postgres.Session.new(Repo)

    renamed = %Renamed{name: "Joe"}
    MessageStore.write(renamed, "person-123")
    
    [person, version] = Store.get(session, "123", include: [:version])
    person.name # => "Joe"
    version # => 0

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

    :timer.sleep(1500)
    # IO.inspect will output `renamed` content
  end
end
```

## Features

### Read from MessageStore

Reading all messages for a given stream name, can be accomplished with:

```elixir
Rill.MessageStore.read(session, "streamName") # Returns a stream
```

A utility is provided for the following common pattern (used in tests):

- Read a message
- Pass the message to a handler
- Repeat the previous 2 steps N times

```elixir
# Handles all messages from "streamName", 5 times
Rill.MessageStore.Reader.handle(session, "streamName", HandlerModule, 5)
```

The `handle` function is provided as utility for testing, it's not meant to
be used in production code. Notice that `handle` returns the `Session`, so it
can be piped.

### Define a Message

```elixir
defmodule Renamed do
  use Rill, :message
  defmessage([:name])
end

message = %Renamed{name: "foo"}
```

### Write to MessageStore

#### Simple write

```elixir
Rill.MessageStore.write(session, message, "streamName")
```

#### Write with expected version

```elixir
Rill.MessageStore.write(session, message, "streamName", expected_version: version)
```

#### Write initial message

```elixir
Rill.MessageStore.write_initial(session, message, "streamName")
```

#### Write batch of messages to the same stream

```elixir
Rill.MessageStore.write(session, [msg1, msg2], "streamName", expected_version: version)
```

### Define a Projection

```elixir
defmodule Person do
  defstruct [name: "", age: 0]
end

defmodule Renamed do
  use Rill, :message
  defmessage([:name])
end

defmodule Person.Projection do
  use Rill, :projection

  @impl Rill.EntityProjection
  # Pattern matching on the first argument it's REQUIRED to determine the
  # struct that needs to be used to decode the message coming from the
  # MessageStore
  deftranslate apply(%Renamed{} = renamed, person) do
    Map.put(person, :name, renamed.name)
  end
end

# A projection is not usually called directly

# Simulates a message coming from the database
message_data = %Rill.MessageStore.MessageData.Read{
  data: %{name: "Joe"},
  type: "Renamed"
}
person = %Person{name: "Fran", age: 29}
person = Person.Projection.apply(person, message_data)

person.name # => "Joe"
```

### Create a Session

A `Rill.Session` is just a struct, but there are some utilities available.

#### Postgres

```elixir
{:ok, _} = Repo.start_link([name: Repo])
session = Rill.MessageStore.Ecto.Postgres.Session.new(repo)
```

#### Memory

```elixir
{:ok, pid} = Rill.MessageStore.Memory.Server.start_link()
session = Rill.MessageStore.Memory.Session.new(pid)
```

### Define a Store

```elixir
defmodule Store do
  use Rill, [
    :store
    # Initial value for the entity, can be omitted and defaults to `nil`
    entity: %Person{},
    # Stream name category
    category: "person",
    # Projection module
    projection: Person.Projection
  ]
end

[person] = Store.fetch("123")

# Including the current version
[person, version] = Store.fetch("123", include: :version) # or [:version]
```

### Define a Handler

```elixir
defmodule Renamed do
  use Rill, :message
  defmessage([:name])
end

defmodule Handler do
  use Rill, :handler

  @impl Rill.Messaging.Handler
  # Pattern matching on the first argument it's REQUIRED to determine the
  # struct that needs to be used to decode the message coming from the
  # MessageStore
  deftranslate handle(%Renamed{} = renamed, _session) do
    IO.inspect(renamed)
    IO.puts("hello")
  end
end

# A handler is not usually called directly

# Simulates a message coming from the database
message_data = %Rill.MessageStore.MessageData.Read{
  data: %{name: "Joe"},
  type: "Renamed"
}

Handler.handle(session, message_data)
```

When a handler is defined using `use Rill, :handler`, the following utilities
are provided:

- `try_version` macro, which rescue any
  `Rill.MessageStore.ExpectedVersion.Error` and returns `nil`
- `MessageStore` is available (automatically aliased)
- `Message` is available (automatically aliased)
- The `stream_name/1`, `/2` and `/3` are imported automatically from
  `Rill.MessageStore.StreamName`

### Start a Consumer

```elixir
Rill.Consumer.start_link([
  # The following arguments are all required
  handlers: [Handler],
  stream_name: "person",
  # Must be supplied to uniquely identify this consumer
  identifier: "personIdentifier",
  session: session
  # Optionally can pass a `condition` argument, handled by the underlying
  # MessageStore adapter
])
```

Alternatively, a `Consumer` can be started from a `Supervisor`:

```elixir
Supervisor.start_link(
  [
    {Rill.Consumer,
     [
       handlers: [Handler],
       stream_name: "person",
       identifier: "personIdentifier",
       session: session
     ]}
  ],
  strategy: :one_for_one
)
```

## TODO

- [ ] Logging
- [ ] Tests
- [ ] More test utilities
- [ ] Position Store
- [ ] Store Cache
- [ ] View Data
