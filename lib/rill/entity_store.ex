defmodule Rill.EntityStore do
  alias Rill.MessageStore.StreamName
  alias Rill.EntityProjection
  alias Rill.Session

  @includes [:id, :version]

  @doc """
  Returns the entity if no include is provided, otherwise a list with entity as
  first element and the other requested fields in the same order as written in
  include option. If the entity does not exists (nothing was written to the
  stream), nil is returned
  """
  @type include_option :: :id | :version
  @type get_option :: [include: include_option()]

  @callback get(session :: Session.t(), id :: String.t(), opts :: get_option()) ::
              nil | any() | list()
  @callback fetch(
              session :: Session.t(),
              id :: String.t(),
              opts :: get_option()
            ) :: any() | list()

  @spec get(
          session :: Session.t(),
          category :: String.t(),
          projection :: module(),
          entity() :: any(),
          id :: String.t(),
          opts :: get_option()
        ) :: any() | list()
  def get(%Session{} = session, category, projection, entity, id, opts \\ []) do
    include =
      opts
      |> Keyword.get(:include, [])
      |> Enum.filter(fn included -> included in @includes end)

    stream_name = StreamName.stream_name(category, id)

    cachable = %{id: nil, entity: entity, version: nil}

    info =
      session.message_store.read(session, stream_name)
      |> Enum.reduce(cachable, fn message_data, cache_info ->
        current_entity = cache_info.entity

        current_entity =
          EntityProjection.apply(projection, current_entity, message_data)

        version = message_data.position
        id = message_data.id

        %{id: id, version: version, entity: current_entity}
      end)

    entity_info =
      if is_nil(info.version),
        do: nil,
        else: info.entity

    include
    |> Enum.reduce([entity_info], fn field, fields ->
      [info[field] | fields]
    end)
    |> Enum.reverse()
  end

  @doc """
  Same as get, but the entity is never nil. If it's nil, the provided entity is
  used
  """
  @spec fetch(
          session :: Session.t(),
          category :: String.t(),
          projection :: module(),
          entity() :: any(),
          id :: String.t(),
          opts :: get_option()
        ) :: any() | list()
  def fetch(%Session{} = session, category, projection, entity, id, opts \\ []) do
    results = get(session, category, projection, entity, id, opts)

    {entity_info, args} = List.pop_at(results, 0)
    entity_info = entity_info || entity
    [entity_info | args]
  end

  defmacro __using__(
             entity: entity,
             category: category,
             projection: projection
           ) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      def get(session, id, opts \\ []) do
        unquote(__MODULE__).get(
          session,
          unquote(category),
          unquote(projection),
          unquote(entity),
          id,
          opts
        )
      end

      def fetch(session, id, opts \\ []) do
        unquote(__MODULE__).fetch(
          session,
          unquote(category),
          unquote(projection),
          unquote(entity),
          id,
          opts
        )
      end
    end
  end
end
