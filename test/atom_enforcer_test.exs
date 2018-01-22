defmodule AtomEnforcerTest do
  use ExUnit.Case
  doctest AtomEnforcer

  def eval(quoted_code), do: fn -> Code.eval_quoted(quoted_code) end
  def should_raise(quoted_code, error), do: assert_raise(error, eval(quoted_code))

  test "compile error for mistyped atom" do
    quote do
      defmodule Test do
        use AtomEnforcer, allowed_atoms: :hey
        def test(:ho), do: 1
      end
    end
    |> should_raise(CompileError)
  end

  test "no error for correctly typed atom" do
    quote do
      defmodule Test2 do
        use AtomEnforcer, allowed_atoms: :hey
        def test(:hey), do: 1
      end
    end
  end

  test "accepts list of atoms" do
    quote do
      defmodule Test3 do
        use AtomEnforcer, allowed_atoms: [:hey, :ho]
        def test(:hey), do: :ho
      end
    end
  end

  test "infers GenServer appropriately" do
    quote do
      defmodule Test4 do
        use AtomEnforcer, allowed_atoms: [:hey, :ho]
        use GenServer
        def init([]), do: {:ok, []} # warning suppression
        def test(:hey), do: :ho
      end
    end
  end

  test "allows denying GenServer" do
    quote do
      defmodule Test5 do
        use AtomEnforcer, infer_genserver: false, allowed_atoms: [:hey, :ho]
        use GenServer
        def init([]), do: {:ok, []} # warning suppression
        def test(:hey), do: :ho
      end
    end
    |> should_raise(CompileError)
  end  

  test "it allows common atoms" do
    quote do
      defmodule Test6 do
        use AtomEnforcer
        def test do
          true
          false
          nil
          :ok
          :error
        end
      end
    end
  end

  test "common_atom option can be turned off" do
    quote do
      defmodule Test7 do
        use AtomEnforcer, allow_common: false
        def test do
          true
          false
          nil
          :ok
          :error
        end
      end
    end
    |> should_raise(CompileError)
  end      
end
