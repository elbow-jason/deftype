defmodule Deftype.Defstruct do

  @behaviour Deftype.Plugin

  def call(_plugin_cfg, _plugins, _metas, attrs) do
    quote do
      defstruct Enum.map(unquote(attrs), fn {name, _, meta} ->
        {name, Keyword.get(meta, :default, nil)}
      end)
    end
  end
end
