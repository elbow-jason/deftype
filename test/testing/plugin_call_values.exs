defmodule Deftype.Testing.PluginCallValues.Asserter do
  @behaviour Deftype.Plugin

  import ExUnit.Assertions

  @impl Deftype.Plugin
  def call(cfg, plugins, metas, attrs) do
    assert cfg == [more: :stuff, right: :here]

    assert plugins == [
             {Deftype.Testing.PluginCallValues.Asserter, [more: :stuff, right: :here]}
           ]

    assert is_list(metas)

    for {key, module} <- metas do
      assert is_atom(key)
      assert is_atom(module)
      assert module.hello() == :world
    end

    assert attrs == [
             {:key1, :string, []},
             {:key2, :integer, [default: 0, virtual: true, child_of: [:thing1, :thing2]]}
           ]
  end
end

defmodule Deftype.Testing.PluginCallValues.My.Nested.HelloWorld do
  def hello, do: :world
end

defmodule Deftype.Testing.PluginCallValues.Impl do
  use Deftype

  alias Deftype.Testing.PluginCallValues.My.Nested.HelloWorld
  alias Deftype.Testing.PluginCallValues.My.Nested.HelloWorld, as: MNHW
  alias Deftype.Testing.PluginCallValues.Asserter

  deftype do
    plugin(Asserter, more: :stuff, right: :here)
    meta(:hello_world_unaliased, Deftype.Testing.PluginCallValues.My.Nested.HelloWorld)
    meta(:hello_world_aliased_as, MNHW)
    meta(:hello_world_aliased_normal, HelloWorld)

    attr(:key1, :string)
    attr(:key2, :integer, default: 0, virtual: true, child_of: [:thing1, :thing2])
  end
end
