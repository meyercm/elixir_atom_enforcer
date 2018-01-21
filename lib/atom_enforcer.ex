defmodule AtomEnforcer do
  import ShorterMaps
  import PredicateSigil

  defmacro __using__(allowed_atoms: q_atoms) do
    quote do
      Module.register_attribute __MODULE__, :__allowed_atoms, accumulate: true, persist: true
      @__allowed_atoms unquote(q_atoms)
      @after_compile AtomEnforcer
    end
  end

  @doc false
  def __after_compile__(~M{%Macro.Env file, line}, bytecode) do
    {:ok, {mod, chunks}} = :beam_lib.chunks(bytecode, [:atoms, :exports, :locals])
    ~M{atoms, exports, locals} = fixup_chunks(chunks) 
    allowed_atoms = Module.get_attribute(mod, :__allowed_atoms) |> List.flatten
    remove = &Kernel.--/2
    atoms
    |> remove.(exports)
    |> remove.(locals)
    |> remove.(allowed_atoms)
    |> remove.(elixir_added_atoms())
    |> remove.([:allowed_atoms])
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

  defp elixir_added_atoms do
    [{:elixir, 'elixir', version}] = Application.loaded_applications |> Enum.filter(~p({:elixir, _, _}))
    do_get_elixir_atoms(version)
  end

  # returns the elixir-added atoms for a given elixir version
  defp do_get_elixir_atoms('1.6.0'), do: [:md5, :compile, :attributes, :module, :deprecated, :functions, :macros, :erlang, :get_module_info]

  defp elixir_module?(atom) do
    case Atom.to_string(atom) do
      "Elixir." <> _rest -> true
      _ -> false
    end
  end

  defp raise_if_any_remain([], _file, _line), do: :ok
  defp raise_if_any_remain(atoms, file, line) do
    raise(CompileError, file: file, line: line, description: "AtomEnforcer found #{inspect atoms} hanging around")
  end
end
