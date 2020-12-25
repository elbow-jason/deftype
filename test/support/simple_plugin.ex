defmodule Deftype.Testing.SimplePlugin do
  @behaviour Deftype.Plugin

  @impl Deftype.Plugin
  def call(cfg, metas, attrs) do
    quote do
      def the_plugin_works do
        {unquote(cfg), unquote(metas), unquote(attrs)}
      end
    end
  end
end
