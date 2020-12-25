# Deftype

Deftype is a simple and flexible lib for defining types in Elixir.

## Usage

```elixir
defmodule MyType do
  use Deftype

  deftype do
    plugin(Deftype.Defstruct)
    attr(:key1, :string)
    attr(:key2, :integer, default: 0, child_of: [:thing1, :thing2])
    meta(:added_by, "elbow-jason")
  end
end
```

There are 5 parts of functionality for Deftype:

  - deftype: The `deftype/1` macro starts a block that allows the use of other parts of functionality that follows

  - plugins: The `plugin/1` and `plugin/2` macros add and execute plugins such as the `Deftype.Defstruct` plugin which defines a struct with the configuration according to the attrs.

  - metas: The `meta/2` macro adds metadata to the MyType module's deftype metas.

  - attrs: The `attr/2` and `attr/3` macros add field keys, field types, and field metadat to the deftype attrs.

  - `__deftype__/1`: The function `__deftype__/1` is defined by the using module of `Deftype` via `use Deftype`. The `__deftype__/1` callback can be used to access all attrs, metas, and plugins defined in the `deftype do` block. For example:

    ```elixir
    MyType.__deftype__(:attrs)
    #=> [{:key1, :string, []}, {:key2, :integer, [default: 0, child_of: [:thing1, :thing2]]}]

    MyType.__deftype__(:plugins)
    #=> [{Deftype.Defstruct, []}]

    MyType.__deftype__(:metas)
    #=> [added_by: "elbow-jason"]
    ```    


## Installation

The package can be installed by adding `deftype` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:deftype, github: "elbow-jason/deftype", branch: "main"}
  ]
end
```

