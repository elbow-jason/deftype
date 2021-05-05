defmodule DeftypeTest do
  use ExUnit.Case
  doctest Deftype

  alias Deftype.Testing.SimplePlugin

  defmodule SimpleAttrs do
    use Deftype

    deftype do
      attr(:key1, :string)
      attr(:key2, :integer, default: 0, virtual: true, child_of: [:thing1, :thing2])
    end
  end

  test "deftype/2 has a name, attrs, and plugins" do
    assert SimpleAttrs.__deftype__(:attrs) == [
             {:key1, :string, []},
             {:key2, :integer, [default: 0, virtual: true, child_of: [:thing1, :thing2]]}
           ]

    assert SimpleAttrs.__deftype__(:plugins) == []
  end

  defmodule Simple2 do
    use Deftype

    deftype do
      meta(:aka, "S2")
      plugin(SimplePlugin, the_plugin_cfg: true)
      attr(:key, :type, some: :meta)
    end
  end

  test "deftype/2 with SimplePlugin works" do
    assert Simple2.__deftype__(:plugins) == [
             {SimplePlugin, [the_plugin_cfg: true]}
           ]

    assert {:the_plugin_works, 0} in Simple2.__info__(:functions)
    cfg = [the_plugin_cfg: true]
    all_plugins = [{Deftype.Testing.SimplePlugin, [the_plugin_cfg: true]}]
    metas = [aka: "S2"]
    attrs = [{:key, :type, [some: :meta]}]

    assert Simple2.the_plugin_works() == {cfg, all_plugins, metas, attrs}
    assert Simple2.__deftype__(:attrs) == [{:key, :type, [some: :meta]}]
    assert Simple2.__deftype__(:metas) == [aka: "S2"]

    assert Simple2.__deftype__(:plugins) == [
             {Deftype.Testing.SimplePlugin, [the_plugin_cfg: true]}
           ]
  end

  defmodule Simple3 do
    use Deftype

    deftype do
      plugin(Deftype.Defstruct)
      attr(:key, :type, some: :meta)
      attr(:key2, :type, some: :meta, default: "some default")
    end
  end

  test "deftype/2 with Defstruct works and sets defaults" do
    assert Simple3.__deftype__(:plugins) == [
             {Deftype.Defstruct, []}
           ]

    assert default_struct = Simple3.__struct__()

    assert %module{} = default_struct
    assert module == Simple3
    assert default_struct.key == nil
    assert default_struct.key2 == "some default"
  end

  # def compile_testing_file(path_rel_to_testing) do
  #   path = Path.join([__DIR__, "testing", path_rel_to_testing])
  #   src = File.read!(path)
  #   quoted = Code.string_to_quoted!(src)
  #   assert {{:module, module, _bytecode, [true]}, _binds} = Code.eval_quoted(quoted)
  #   assert is_atom(module)
  #   module
  # end

  describe "internal callbacks" do
    test "work" do
      module = Deftype.Testing.SimplePluginNoQuote.Impl

      assert module.__deftype__(:attrs) == [
               {:key1, :string, []},
               {:key2, :integer, [default: 0, virtual: true, child_of: [:thing1, :thing2]]}
             ]

      assert module.__deftype__(:metas) == [
               hello_world_unaliased: Deftype.Testing.SimplePluginNoQuote.My.Nested.HelloWorld,
               hello_world_aliased_as: Deftype.Testing.SimplePluginNoQuote.My.Nested.HelloWorld,
               hello_world_aliased_normal:
                 Deftype.Testing.SimplePluginNoQuote.My.Nested.HelloWorld
             ]

      assert module.__deftype__(:plugins) == [
               {Deftype.Testing.SimplePluginNoQuote,
                [primary_key: {:id, :binary_id, []}, more: :stuff, right: :here]}
             ]
    end
  end
end
