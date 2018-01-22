defmodule AtomEnforcer do
  import ShorterMaps
  import PredicateSigil

  @moduledoc """
  Ever have a GenServer crash because you misspelled the atom in the handle_XXX?
  
  AtomEnforcer provides compile-time checking that your code only uses the atoms defined in
  `use AtomEnforcer, allowed_atoms: [some_atoms]`.  For example:

  ```elixir
  defmodule MyGenServer do
    use GenServer
    use AtomEnforcer, allowed_atoms: [:execute_work]

    def execute(pid, args) do
      GenServer.call(pid, {:execute_main_work_task, args})
    end

    def init(), do: {:ok, []}

    def handle_call({:execte_main_work_task, args}, _from, state) do
      {:reply, :not_yet_implemented, state}
    end
  end
  ```

  This module will raise a CompileError:
  ** (CompileError): AtomEnforcer found [:execte_main_work_task] hanging around
  """
  defmacro __using__(q_opts) do
    quote do
      Module.register_attribute __MODULE__, :__atom_enforcer_opts, persist: true
      @__atom_enforcer_opts unquote(q_opts)
      @after_compile AtomEnforcer
    end
  end
  
  def genserver_atoms do
    [:ok, :start_link, :start, :self, :registered_name, :info, :phash2, :bad_call,
     :stop, :inspect, :byte_size, :all, :exception, :error, :bad_cast, :error_logger,
     :error_msg, :noreply, :hibernate, :ignore, :noreply, :reply, :down, :normal, :shutdown]

  end

  def common_atoms do
    [:ok, :error, true, false, nil]
  end

  @default_opts [infer_genserver: true, allowed_atoms: [], allow_common: true]
  @doc false
  def __after_compile__(~M{%Macro.Env file, line}, bytecode) do
    {:ok, {mod, chunks}} = :beam_lib.chunks(bytecode, [:atoms, :exports, :locals])
    opts = @default_opts
           |> Keyword.merge(Module.get_attribute(mod, :__atom_enforcer_opts))
           |> Enum.into(%{})
    allowed_atoms = calc_allowed(mod, opts)
    ~M{atoms, exports, locals} = fixup_chunks(chunks) 
    remove = &Kernel.--/2
    atoms
    |> remove.(exports)
    |> remove.(locals)
    |> remove.(allowed_atoms)
    |> remove.(elixir_added_atoms())
    |> Enum.reject(&elixir_module?/1)
    |> raise_if_any_remain(file, line)
  end

  # takes the chunks as :beam_lib provides them, and converts them to lists of atoms
  defp fixup_chunks(chunk_list, acc \\%{})
  defp fixup_chunks([], acc), do: acc
  defp fixup_chunks([{:atoms, raw_atoms}|rest], acc) do
    atoms = Enum.map(raw_atoms, fn {_, atom} -> atom end)
    fixup_chunks(rest, Map.put(acc, :atoms, atoms))
  end
  defp fixup_chunks([{:exports, raw_exports}|rest], acc) do
    exports = Enum.map(raw_exports, fn {atom, _arity} -> atom end)
    fixup_chunks(rest, Map.put(acc, :exports, exports))
  end
  defp fixup_chunks([{:locals, raw_locals}|rest], acc) do
    locals = Enum.map(raw_locals, fn {atom, _arity} -> atom end)
    fixup_chunks(rest, Map.put(acc, :locals, locals))
  end

  defp calc_allowed(mod, ~M{infer_genserver, allowed_atoms, allow_common}) do
    allowed_atoms = (is_list(allowed_atoms) && allowed_atoms || [allowed_atoms])
    allowed_atoms = allowed_atoms ++ (is_genserver?(mod) and infer_genserver) && genserver_atoms() || []  
    allowed_atoms = allowed_atoms ++ (allow_common && common_atoms() || [])
    allowed_atoms
  end

  defp is_genserver?(module) do
    case module.module_info[:attributes][:behaviours] do
      list when is_list(list) -> Enum.member?(list, GenServer)
      _ -> false
    end
  end

  defp elixir_added_atoms do
    [{:elixir, 'elixir', version}] = Application.loaded_applications |> Enum.filter(~p({:elixir, _, _}))
    do_get_elixir_atoms(version)
  end

  # returns the elixir-added atoms for a given elixir version
  defp do_get_elixir_atoms('1.6.0'), do: [:md5, :compile, :attributes, :module, :deprecated, :functions, :macros, :erlang, :get_module_info]

  # filter predicate to differentiate `:an_atom` from `AnElixirModule` 
  defp elixir_module?(atom) do
    case Atom.to_string(atom) do
      "Elixir." <> _rest -> true
      _ -> false
    end
  end

  # Raises a compile error if any atoms remain in the list of discovered atoms after removing legit atoms
  defp raise_if_any_remain([], _file, _line), do: :ok
  defp raise_if_any_remain(atoms, file, line) do
    raise(CompileError, file: file, line: line, description: "AtomEnforcer found #{inspect atoms} hanging around")
  end
end
