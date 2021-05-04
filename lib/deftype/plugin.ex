defmodule Deftype.Plugin do
  @moduledoc """
  Inject code into deftype definitions.
  """

  @type cfg :: any()
  @type plugins() :: [{module(), cfg}]
  @type metas :: Deftype.metas()
  @type attrs :: Deftype.attrs()

  @callback call(cfg(), plugins(), metas(), attrs()) :: Macro.t()

  @doc false
  def call(mod, cfg, plugins, metas, attrs) do
    mod.call(cfg, plugins, metas, attrs)
  end
end
