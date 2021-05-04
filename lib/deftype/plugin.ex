defmodule Deftype.Plugin do
  @moduledoc """
  Inject code into deftype definitions.
  """

  @type cfg :: any()
  @type plugins() :: [{module(), cfg}]
  @type metas :: Deftype.metas()
  @type attrs :: Deftype.attrs()

  @type compile_step :: :inline | :before_compile

  @callback call(cfg(), plugins(), metas(), attrs()) :: Macro.t()

  @callback call_during(cfg(), plugins(), metas(), attrs()) :: compile_step()

  @optional_callbacks [call_during: 4]

  defguardp is_step(s) when s in [:inline, :before_compile]

  @spec call_during(atom, any, any, any, any) :: any
  def call_during(mod, cfg, plugins, metas, attrs) do
    if function_exported?(mod, :call_during, 4) do
      step = mod.call_during(cfg, plugins, metas, attrs)

      if not is_step(step) do
        raise ArgumentError, """
        Deftype.Plugin implementation is invalid - #{inspect(mod)}.call_during/4
        returned step #{inspect(step)}, but only :inline and :before_compile are
        supported2.
        """
      end

      step
    else
      :before_compile
    end
  end

  @doc false
  def call(mod, cfg, plugins, metas, attrs) do
    mod.call(cfg, plugins, metas, attrs)
  end

  def call_step(step, mod, cfg, plugins, metas, attrs) when is_step(step) do
    if call_during(mod, cfg, plugins, metas, attrs) == step do
      call(mod, cfg, plugins, metas, attrs)
    else
      []
    end
  end
end
