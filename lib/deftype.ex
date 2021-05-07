defmodule Deftype do
  def plugins(type), do: type.__deftype__(:plugins)

  def metas(type), do: type.__deftype__(:metas)

  def attrs(type), do: type.__deftype__(:attrs)

  @doc false
  @spec __using__(Keyword.t()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      import Deftype.Macros, only: [deftype: 1]
    end
  end
end
