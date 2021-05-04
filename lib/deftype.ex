defmodule Deftype do
  def plugins(type), do: type.__deftype__(:plugins)

  def metas(type), do: type.__deftype__(:metas)

  def attrs(type), do: type.__deftype__(:attrs)

  @doc false
  @spec __using__(Keyword.t()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      import Deftype.Macros, only: [deftype: 1]

      @before_compile Deftype
    end
  end

  @doc false
  @spec __using__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(_env) do
    # generate the AST of the plugins.
    alias Deftype.Plugin
    caller_mod = __CALLER__.module

    metas = Module.get_attribute(caller_mod, :__deftype_metas)
    metas_ast = Macro.escape(metas)

    attrs = Module.get_attribute(caller_mod, :__deftype_attrs)
    attrs_ast = Macro.escape(attrs)

    plugins = Module.get_attribute(caller_mod, :__deftype_plugins)

    Enum.map(plugins, fn {plugin, cfg} ->
      Plugin.call(plugin, cfg, plugins, metas_ast, attrs_ast)
    end)
  end
end
