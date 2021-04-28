defmodule WebserverTest do
  use ExUnit.Case
  doctest Webserver

  test "greets the world" do
    assert Webserver.hello() == :world
  end
end
