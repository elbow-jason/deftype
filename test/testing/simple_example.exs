defmodule Deftype.Testing.SimpleExample do
  use Deftype

  deftype do
    plugin(Deftype.Defstruct)
    meta(:example?, true)
    attr(:name, :string)
    attr(:age, :integer, child: 0..17, adult: 18..64, senior: 65..2000)
  end
end
