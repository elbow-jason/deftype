defmodule Deftype.Testing.SimplePlugin do
  @behaviour Deftype.Plugin

  @impl Deftype.Plugin
  def call(cfg, plugins, metas, attrs) do
    cfg = Macro.escape(cfg)
    plugins = Macro.escape(plugins)
    metas = Macro.escape(metas)
    attrs = Macro.escape(attrs)

    quote do
      def the_plugin_works do
        {unquote(cfg), unquote(plugins), unquote(metas), unquote(attrs)}
      end
    end
  end
end
