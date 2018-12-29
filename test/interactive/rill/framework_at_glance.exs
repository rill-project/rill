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
    IO.inspect(renamed, label: :renamed)
  end
end

defmodule Run do
  def run do
    # {:ok, pid1} = Rill.MessageStore.Memory.start_link()
    Rill.MessageStore.Mnesia.start()

    # session = Rill.MessageStore.Memory.Session.new(pid1)
    session = Rill.MessageStore.Mnesia.Session.new("MemoryMnesia")
    session2 = Rill.MessageStore.Mnesia.Session.new("MemoryMnesia2")

    renamed = %Renamed{name: "Joe"}
    renamed2 = %Renamed{name: "John"}
    Rill.MessageStore.write(session, renamed, "person-123")
    Rill.MessageStore.write(session, renamed2, "person-123")
    Rill.MessageStore.write(session2, renamed, "person-456")

    [person, version] = Store.fetch(session, "123", include: [:version])

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
    IO.inspect(person, label: :person)
    IO.inspect(version, label: :version)
    Rill.MessageStore.Mnesia.info(session)
    Rill.MessageStore.Mnesia.truncate(session)

    [empty_person, empty_version] =
      Store.fetch(session, "123", include: [:version])

    [person2, version2] = Store.fetch(session2, "456", include: [:version])
    IO.inspect({empty_person, empty_version}, label: :empty_person)
    IO.inspect({person2, version2}, label: :person2)
  end
end

Run.run()
