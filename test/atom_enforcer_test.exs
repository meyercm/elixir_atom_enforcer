defmodule AtomEnforcerTest do
  use ExUnit.Case
  doctest AtomEnforcer

  test "greets the world" do
    assert AtomEnforcer.hello() == :world
  end
end
