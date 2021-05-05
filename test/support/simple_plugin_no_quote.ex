defmodule Deftype.Testing.SimplePluginNoQuote do
  @behaviour Deftype.Plugin

  import ExUnit.Assertions

  @impl Deftype.Plugin
  def call(cfg, plugins, metas, attrs) do
    assert match?(
             [
               primary_key: {:{}, [line: _], [:id, :binary_id, []]},
               more: :stuff,
               right: :here
             ],
             cfg
           )

    assert match?([{__MODULE__, ^cfg}], plugins)

    assert is_list(metas)

    for {key, module} <- metas do
      assert is_atom(key)
      assert match?({:__aliases__, _, [_ | _]}, module)
    end

    assert match?(
             [
               {:{}, _, [:key1, :string, []]},
               {:{}, _,
                [:key2, :integer, [default: 0, virtual: true, child_of: [:thing1, :thing2]]]}
             ],
             attrs
           )

    Macro.escape({cfg, plugins, metas, attrs})
  end
end

defmodule Deftype.Testing.SimplePluginNoQuote.My.Nested.HelloWorld do
  def hello, do: :world
end

defmodule Deftype.Testing.SimplePluginNoQuote.Impl do
  use Deftype

  alias Deftype.Testing.SimplePluginNoQuote.My.Nested.HelloWorld
  alias Deftype.Testing.SimplePluginNoQuote.My.Nested.HelloWorld, as: MNHW
  alias Deftype.Testing.SimplePluginNoQuote

  deftype do
    plugin(SimplePluginNoQuote, primary_key: {:id, :binary_id, []}, more: :stuff, right: :here)
    meta(:hello_world_unaliased, Deftype.Testing.SimplePluginNoQuote.My.Nested.HelloWorld)
    meta(:hello_world_aliased_as, MNHW)
    meta(:hello_world_aliased_normal, HelloWorld)

    attr(:key1, :string)
    attr(:key2, :integer, default: 0, virtual: true, child_of: [:thing1, :thing2])
  end
end
