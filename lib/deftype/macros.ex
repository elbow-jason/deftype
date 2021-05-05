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

  defp extract(caller, {:__block__, _, block}) do
    {:ok, agent} = init_agent()
    :ok = Enum.each(block, fn entry -> build_add_entries(caller, agent, entry) end)

    agent
    |> Agent.get(fn entries -> entries end)
    |> Map.update!(:attrs, &Enum.reverse/1)
    |> Map.update!(:metas, &Enum.reverse/1)
    |> Map.update!(:plugins, &Enum.reverse/1)
  end

  def init_agent do
    Agent.start_link(fn ->
      %{
        attrs: [],
        metas: [],
        plugins: [],
        aliased: []
      }
    end)
  end

  defp add_entry(agent, {key, value}) do
    Agent.update(agent, fn acc ->
      Map.update!(acc, key, fn prev -> [value | prev] end)
    end)
  end

  defp add_entry(agent, entries) when is_list(entries) do
    Enum.each(entries, fn entry ->
      :ok = add_entry(agent, entry)
    end)
  end

  defp build_add_entries(caller, agent, {:attr, _, [name, type]}) do
    name = resolve_value(caller, agent, name)
    type = resolve_value(caller, agent, type)
    add_entry(agent, {:attrs, {name, type, []}})
  end

  defp build_add_entries(caller, agent, {:attr, _, [name, type, config]}) do
    name = resolve_value(caller, agent, name)
    type = resolve_value(caller, agent, type)
    config = resolve_value(caller, agent, config)
    add_entry(agent, {:attrs, {name, type, config}})
  end

  defp build_add_entries(caller, agent, {:meta, _, [key, value]}) do
    key = resolve_value(caller, agent, key)
    value = resolve_value(caller, agent, value)
    add_entry(agent, {:metas, {key, value}})
  end

  defp build_add_entries(caller, agent, {:plugin, _, [module_ast]}) do
    module = resolve_value(caller, agent, module_ast)
    add_entry(agent, {:plugins, {module, []}})
  end

  defp build_add_entries(caller, agent, {:plugin, _, [module, config]}) do
    module = resolve_value(caller, agent, module)
    config = resolve_value(caller, agent, config)
    add_entry(agent, {:plugins, {module, config}})
  end

  defp build_add_entries(_caller, got, _agent) do
    raise "unhandled Deftype entry: \n#{Macro.to_string(got)}\n"
  end

  defguardp is_scalar(v) when is_number(v) or is_binary(v) or is_atom(v)

  defp resolve_value(caller, agent, {:__aliases__, _, parts} = aliased) do
    :ok = add_entry(agent, {:aliased, aliased})
    short_name = Module.concat(parts)
    long_name = Keyword.get(caller.aliases, short_name, short_name)
    resolve_value(caller, agent, long_name)
  end

  defp resolve_value(caller, agent, {key, meta, args}) do
    args = Enum.map(args, fn a -> resolve_value(caller, agent, a) end)
    {resolve_value(caller, agent, key), meta, args}
  end

  defp resolve_value(_caller, _agent, val) when is_scalar(val) do
    val
  end

  defp resolve_value(caller, agent, list) when is_list(list) do
    Enum.map(list, fn item -> resolve_value(caller, agent, item) end)
  end

  defp resolve_value(caller, agent, {k, v}) do
    {resolve_value(caller, agent, k), resolve_value(caller, agent, v)}
  end

  defmacro deftype(do: block) do
    context = extract(__CALLER__, block)
    {aliased, context} = Map.pop!(context, :aliased)
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

    aliases_used =
      for module <- aliased do
        quote do
          # silence unused alias warnings
          _ = unquote(module).__info__(:functions)
        end
      end

    postlude = inline_plugins(context)

    quote do
      unquote(prelude)
      unquote(aliases_used)
      unquote(postlude)
    end
  end
end
