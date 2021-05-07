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

    plugins_ast =
      Enum.map(plugins, fn {plugin, cfg} ->
        Plugin.call(plugin, cfg, plugins, metas, attrs)
      end)

    {:__block__, [], plugins_ast}
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

  defp build_add_entries(_caller, agent, {:attr, meta, [name, type]}) do
    entry = {:{}, meta, [name, type, []]}
    add_entry(agent, {:attrs, entry})
  end

  defp build_add_entries(_caller, agent, {:attr, meta, [name, type, config]}) do
    entry = {:{}, meta, [name, type, config]}
    add_entry(agent, {:attrs, entry})
  end

  defp build_add_entries(_caller, agent, {:meta, _, [key, value]}) do
    add_entry(agent, {:metas, {key, value}})
  end

  defp build_add_entries(caller, agent, {:plugin, _, [module_ast]}) do
    module = resolve_module(caller, agent, module_ast)
    add_entry(agent, {:plugins, {module, []}})
  end

  defp build_add_entries(caller, agent, {:plugin, _, [module, config]}) do
    module = resolve_module(caller, agent, module)
    add_entry(agent, {:plugins, {module, config}})
  end

  defp build_add_entries(_caller, _agent, got) do
    raise """
    Unhandled Deftype entry!

    code: \n#{Macro.to_string(got)}\n

    ast: \n#{inspect(got)}\n
    """
  end

  defp resolve_module(caller, agent, {:__aliases__, _, parts} = aliased) do
    :ok = add_entry(agent, {:aliased, aliased})
    short_name = Module.concat(parts)
    long_name = Keyword.get(caller.aliases, short_name, short_name)

    case long_name do
      {:__aliases__, _, long_parts} ->
        Module.concat(long_parts)

      module when is_atom(module) ->
        module
    end
  end

  defmacro deftype(do: block) do
    context = extract(__CALLER__, block)

    %{
      aliased: aliased,
      attrs: attrs,
      metas: metas,
      plugins: plugins
    } = context

    prelude =
      quote do
        import Deftype.Macros, only: [attr: 3, attr: 2, plugin: 1, plugin: 2, meta: 2]

        def __deftype__(:attrs), do: unquote(attrs)
        def __deftype__(:metas), do: unquote(metas)
        def __deftype__(:plugins), do: unquote(plugins)
      end

    aliases_used =
      for module <- aliased do
        quote do
          if Code.ensure_loaded?(unquote(module)) && function_exported?(unquote(module), :info, 1) do
            # hack: silence unused alias warnings
            _ = unquote(module).__info__(:functions)
          end
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
