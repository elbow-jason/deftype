defmodule Deftype.Defstruct do
  @behaviour Deftype.Plugin

  def call_during(_, _, _, _) do
    :inline
  end

  def call(_plugin_cfg, _plugins, _metas, _attrs) do
    quote do
      []
    end
  end

  def attrs_to_struct_fields(attrs) do
    Enum.map(attrs, fn {name, _, meta} ->
      {name, Keyword.get(meta, :default, nil)}
    end)
  end
end
