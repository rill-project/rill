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
