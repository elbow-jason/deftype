defmodule Deftype.Plugin do
  @moduledoc """
  Inject code into deftype definitions.
  """

  @type cfg :: any()
  @type plugins() :: [{module(), cfg}]

  @callback call(cfg, plugins(), Deftype.metas(), Deftype.attrs()) :: Macro.t()

  @doc false
  def call(mod, cfg, plugins, metas, attrs) do
    mod.call(cfg, plugins, metas, attrs)
  end
end
