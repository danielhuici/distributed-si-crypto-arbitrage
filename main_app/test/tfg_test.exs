defmodule TfgTest do
  use ExUnit.Case
  doctest Tfg

  test "greets the world" do
    assert Tfg.hello() == :world
  end
end
