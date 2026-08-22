defmodule TypedLispTest do
  use ExUnit.Case
  doctest TypedLisp

  test "greets the world" do
    assert TypedLisp.hello() == :world
  end
end
