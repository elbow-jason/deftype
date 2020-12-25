defmodule Deftype do
  alias Deftype.Plugin

  @type plugin_cfg :: Plugin.cfg()

  @type name :: String.t()

  @type metas :: Keyword.t()

  @type attr_key :: atom()
  @type attr_type :: module() | atom() | {:list, module() | atom()}
  @type attr_meta :: Keyword.t()

  @type attrs :: {attr_key(), attr_type(), attr_meta()}

  defmacro plugin(mod, cfg \\ []) do
    quote do
      item = {unquote(mod), unquote(cfg)}
      Module.put_attribute(__MODULE__, :__raw_deftype_plugins, item)
    end
  end

  defmacro attr(key, type, meta \\ []) when is_atom(key) and is_list(meta) do
    quote do
      item = {unquote(key), unquote(type), unquote(meta)}
      Module.put_attribute(__MODULE__, :__raw_deftype_attrs, item)
    end
  end

  defmacro meta(key, value) when is_atom(key) do
    quote do
      item = {unquote(key), unquote(value)}
      Module.put_attribute(__MODULE__, :__raw_deftype_metas, item)
    end
  end

  defmacro deftype(do: block) do
    quote do
      # setup accumulating module attrs
      Module.register_attribute(__MODULE__, :__raw_deftype_attrs, accumulate: true)
      Module.register_attribute(__MODULE__, :__raw_deftype_metas, accumulate: true)
      Module.register_attribute(__MODULE__, :__raw_deftype_plugins, accumulate: true)

      # import macros for use in the block
      import Deftype, only: [attr: 3, attr: 2, plugin: 1, plugin: 2, meta: 2]

      # inject the block
      unquote(block)

      @__deftype_attrs Enum.reverse(@__raw_deftype_attrs)
      @__deftype_metas Enum.reverse(@__raw_deftype_metas)
      @__deftype_plugins Enum.reverse(@__raw_deftype_plugins)

      Module.delete_attribute(__MODULE__, :__raw_deftype_attrs)
      Module.delete_attribute(__MODULE__, :__raw_deftype_plugins)
      Module.delete_attribute(__MODULE__, :__raw_deftype_metas)

      def __deftype__(:attrs), do: @__deftype_attrs
      def __deftype__(:metas), do: @__deftype_metas
      def __deftype__(:plugins), do: @__deftype_plugins
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Deftype, only: [deftype: 1]

      @before_compile Deftype
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    # generate the AST of the plugins.
    alias Deftype.Plugin
    caller_mod = __CALLER__.module

    metas = Module.get_attribute(caller_mod, :__deftype_metas)
    metas_ast = Macro.escape(metas)

    attrs = Module.get_attribute(caller_mod, :__deftype_attrs)
    attrs_ast = Macro.escape(attrs)

    plugins = Module.get_attribute(caller_mod, :__deftype_plugins)
    Enum.map(plugins, fn {plugin, cfg} -> Plugin.call(plugin, cfg, metas_ast, attrs_ast) end)
  end
end
