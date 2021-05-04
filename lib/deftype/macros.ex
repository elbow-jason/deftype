defmodule Deftype.Macros do
  alias Deftype.Plugin

  @type plugin_cfg :: Plugin.cfg()

  @type name :: String.t()

  @type metas :: Keyword.t()

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
      import Deftype.Macros, only: [attr: 3, attr: 2, plugin: 1, plugin: 2, meta: 2]

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

      # this is inlined because `defstruct` does not "act right"
      # when not inlined.
      if Deftype.Defstruct in Enum.map(@__deftype_plugins, fn {p, _} -> p end) do
        @struct_fields Deftype.Defstruct.attrs_to_struct_fields(@__deftype_attrs)

        defstruct @struct_fields
      end
    end
  end
end
