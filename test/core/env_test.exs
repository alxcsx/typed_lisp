defmodule Core.EnvTest do
  use ExUnit.Case, async: true
  alias Core.Env

  describe "Env Instatiation" do
    test "Empty Env" do
      env = Env.new()
      assert env.vars == %{}
      assert env.types == %{}
      assert env.macros == %{}
      assert env.vars == %{}
      assert env.parent == nil
    end

    test "Nested Env" do
      parent = Env.new()
      child = Env.new(parent)
      assert child.parent == parent
    end
  end

  describe "Variable Lookup" do
    test "Find on Current Scope" do
      env = %{Env.new() | vars: %{"x" => 10}}
      assert Env.get_var(env, "x") == 10
    end

    test "Find on Parent Scope" do
      parent = %{Env.new() | vars: %{"x" => 10}}
      child = Env.new(parent)
      assert Env.get_var(child, "x") == 10
    end

    test "Parent Scope Shadowing" do
      parent = %{Env.new() | vars: %{"x" => 10}}
      child = %{Env.new(parent) | vars: %{"x" => 20}}

      assert Env.get_var(child, "x") == 20
      assert Env.get_var(parent, "x") == 10
    end

    test "Return Nil for non-existing keys" do
      env = Env.new()
      assert Env.get_var(env, "misisng") == nil
    end
  end
end
