## AtomEnforcer

`AtomEnforcer` exists to solve a problem encountered in production code- preventing 
run-time errors for mismatched atoms between sends and receieves, especially in GenServer
APIs and `handle_((call|cast|info)` function heads.

The strategy is to explicitly allow certain atoms to exist within a module, and then, at
compile time, raise an error if an atom is used which has not been allowed.

### Getting Started

1. add `{:atom_enforcer, "~> 0.1"},` to your `mix.deps`
2. add `use AtomEnforcer, allowed_atoms: <atoms you want to use>` to a module
3. find your atom typos at compile time now

### API

The only API for `AtomEnforcer` is the `__using__` macro and it's options:

  - `allowed_atoms`: a single atom or a list of atoms which are allowed to exist in this
    module.
  - `allow_common`: (default true) automatically whitelists `[:ok, :error, true, false, nil]`
  - `infer_genserver`: (default true) If the module is a GenServer, automatically whitelists
    atoms used in genserver callbacks. See documentation for the full list.

### Salient Example

```elixir
#TODO: improve this example 
defmodule SomeGenServer do
  use GenServer
  use AtomEnforcer, allowed_atoms: [:api_call_1]

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def api_call_1(args) do
    GenServer.call(__MODULE__, {:api_call_1, args}) 
  end

  def init([]), do: {:ok, []}

  # The misspelling on the next line will cause a CompileError to be thrown
  def handle_call({:ap_call_1, args}, _from, state) do
    {:reply, args, state}
  end

end

```

### Closing Comments

Please drop me a note if you end up using AtomEnforcer in something cool, or file an
issue if you have difficulty, bugs, or ideas for a better API.
