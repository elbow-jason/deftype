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
    attrs =  [{:key, :type, [some: :meta]}]

    assert Simple2.the_plugin_works() == {cfg, all_plugins, metas, attrs}
    assert Simple2.__deftype__(:attrs) == [{:key, :type, [some: :meta]}]
    assert Simple2.__deftype__(:metas) == [aka: "S2"]
    assert Simple2.__deftype__(:plugins) == [{Deftype.Testing.SimplePlugin, [the_plugin_cfg: true]}]
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

    assert %Simple3{} == %Simple3{
      key: nil,
      key2: "some default",
    }
  end


end
