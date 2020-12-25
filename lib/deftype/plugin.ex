defmodule Deftype.Plugin do
  @moduledoc """
  Inject code into deftype definitions.
  """

  @type cfg :: any()

  @callback call(cfg(), Deftype.metas(), Deftype.attrs()) :: Macro.t()

  @doc false
  def call(mod, cfg, metas, attrs) do
    mod.call(cfg, metas, attrs)
  end
end
