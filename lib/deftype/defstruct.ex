defmodule Deftype.Defstruct do
  @behaviour Deftype.Plugin

  def call_during(_, _, _, _) do
    :inline
  end

  def call(_plugin_cfg, _plugins, _metas, attrs) do
    quote do
      defstruct Enum.map(unquote(attrs), fn {name, _, meta} ->
                  {name, Keyword.get(meta, :default, nil)}
                end)
    end
  end
end
