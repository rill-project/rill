defmodule Rill.Messaging.Message.Dictionary do
  @moduledoc """
  Converts messages from database representation to the related struct
  """

  defstruct type_names: %{}

  @callback dictionary() :: %__MODULE__{}

  alias Rill.MessageStore.MessageData.Read

  @typedoc """
  Used as a dictionary to convert a type name (text) into its related module
  """
  @type t :: %__MODULE__{type_names: %{optional(String.t()) => module()}}

  @spec translate_name(dictionary :: %__MODULE__{}, type :: String.t()) ::
          nil | module()
  def translate_name(%__MODULE__{type_names: names}, type)
      when is_binary(type) do
    Map.get(names, type)
  end

  @spec translate(module :: module(), message_data :: %Read{}) :: nil | struct()
  def translate(module, %Read{} = message_data) when is_atom(module) do
    module
    |> get_dictionary()
    |> translate(message_data)
  end

  @spec translate(dictionary :: %__MODULE__{}, message_data :: %Read{}) ::
          nil | struct()
  def translate(%__MODULE__{} = dictionary, %Read{} = message_data) do
    type = message_data.type
    module = translate_name(dictionary, type)

    if is_nil(module) do
      nil
    else
      module.build(message_data)
    end
  end

  @spec get_dictionary(module :: module()) :: %__MODULE__{}
  def get_dictionary(module) when is_atom(module) do
    module.dictionary() || %__MODULE__{}
  end

  @doc """
  Provides `def` macro and sets up `dictionary` callback
  """
  defmacro __using__(opts \\ []) do
    provide_dictionary = Keyword.get(opts, :provide_dictionary, true)

    if provide_dictionary do
      quote do
        require unquote(__MODULE__)
        import Kernel, except: [def: 2]
        import unquote(__MODULE__), only: [def: 2]
        @behaviour unquote(__MODULE__)
        @before_compile unquote(__MODULE__).Provider
      end
    else
      quote do
        require unquote(__MODULE__)
        import Kernel, except: [def: 2]
        import unquote(__MODULE__), only: [def: 2]
        @behaviour unquote(__MODULE__)
      end
    end
  end

  @doc """
  Defines a function and appends the type of the first argument (must be a
  struct) to the dictionary of the module.

  ## Examples

  ```
  defmodule Foo.Bar do
    defstruct [:name, :age]
  end

  defmodule Projection do
    alias Foo.Bar

    def apply(%Bar{} = bar, entity) do
      # ...
    end
  end

  Rill.Message.Dictionary.get_dictionary(Projection)
  # %Projection{type_names: %{"Bar" => Foo.Bar}}
  ```
  """
  defmacro def(head, do: body) do
    {_fun_name, _ctx, args} = head
    {:=, _, module_args} = List.first(args)
    {:%, _, module_match} = List.first(module_args)
    module_quoted = List.first(module_match)
    module = Macro.expand(module_quoted, __CALLER__)

    type =
      module
      |> Module.split()
      |> List.last()

    dictionary = Module.get_attribute(__CALLER__.module, :__rill_translate__)
    dictionary = dictionary || %__MODULE__{}
    type_names = Map.put(dictionary.type_names, type, module)
    dictionary = Map.put(dictionary, :type_names, type_names)

    Module.register_attribute(__CALLER__.module, :__rill_translate__,
      persist: true
    )

    Module.put_attribute(__CALLER__.module, :__rill_translate__, dictionary)

    quote do
      def unquote(head) do
        unquote(body)
      end
    end
  end
end
