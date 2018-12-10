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
    {:ok, pid1} = Rill.MessageStore.Memory.start_link()

    session = Rill.MessageStore.Memory.Session.new(pid1)

    renamed = %Renamed{name: "Joe"}
    Rill.MessageStore.write(session, renamed, "person-123")

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
  end
end

Run.run()
