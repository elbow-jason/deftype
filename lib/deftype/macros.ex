defmodule Deftype.Macros do
  alias Deftype.Plugin

  @type plugin_cfg :: Plugin.cfg()

  @type name :: String.t()

  @type metas :: Keyword.t()

  def plugin(_mod, _cfg \\ []) do
    :ok
  end

  def attr(_key, _type, _meta \\ []) do
    :ok
  end

  def meta(_key, _value) do
    :ok
  end

  defp inline_plugins(context) do
    attrs = Map.fetch!(context, :attrs)
    metas = Map.fetch!(context, :metas)
    plugins = Map.fetch!(context, :plugins)

    Enum.map(plugins, fn {plugin, cfg} ->
      Plugin.call(plugin, cfg, plugins, metas, attrs)
    end)
  end

  defp extract(caller, {:__block__, [], block}) do
    init_acc = %{
      attrs: [],
      metas: [],
      plugins: []
    }

    block
    |> Enum.reduce(init_acc, fn
      entry_ast, acc ->
        {key, entry} = build_entry(caller, entry_ast)
        Map.update!(acc, key, fn prev -> [entry | prev] end)
    end)
    |> Map.update!(:attrs, &Enum.reverse/1)
    |> Map.update!(:metas, &Enum.reverse/1)
    |> Map.update!(:plugins, &Enum.reverse/1)
  end

  defp build_entry(_caller, {:attr, _, [name, type]}) do
    {:attrs, {name, type, []}}
  end

  defp build_entry(_caller, {:attr, _, [name, type, config]}) do
    {:attrs, {name, type, config}}
  end

  defp build_entry(_caller, {:meta, _, [key, value]}) do
    {:metas, {key, value}}
  end

  defp build_entry(caller, {:plugin, _, [module]}) do
    {:plugins, {module_to_name(caller, module), []}}
  end

  defp build_entry(caller, {:plugin, _, [module, config]}) do
    {:plugins, {module_to_name(caller, module), config}}
  end

  defp build_entry(_caller, got) do
    raise "unhandled Deftype entry: \n#{Macro.to_string(got)}\n"
  end

  defp module_to_name(caller, {:__aliases__, _, parts}) do
    short_name = Module.concat(parts)
    Keyword.get(caller.aliases, short_name, short_name)
  end

  defmacro deftype(do: block) do
    context = extract(__CALLER__, block)
    context_ast = Macro.escape(context)

    prelude =
      quote do
        import Deftype.Macros, only: [attr: 3, attr: 2, plugin: 1, plugin: 2, meta: 2]

        @__deftype_attrs Map.fetch!(unquote(context_ast), :attrs)
        @__deftype_metas Map.fetch!(unquote(context_ast), :metas)
        @__deftype_plugins Map.fetch!(unquote(context_ast), :plugins)

        def __deftype__(:attrs), do: @__deftype_attrs
        def __deftype__(:metas), do: @__deftype_metas
        def __deftype__(:plugins), do: @__deftype_plugins
      end

    postlude = inline_plugins(context)

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end
end
