defmodule Midfield.MacroExpanderTests do
  use ExUnit.Case
  alias Midfield.MacroExpander

  alias Core.AST
  alias Core.Env
  alias Midfield.MacroExpander

  # --- Helpers ---
  def id(name), do: %AST.Identifier{name: name}
  def int(val), do: %AST.Literal{type: :Int, value: val}
  def lst(elems), do: %AST.List{elements: elems}
  def tup(elems), do: %AST.Tuple{elements: elems}

  describe "AST Expansion" do
    test "expands regular expressions into Call structs" do
      env = Env.new()
      # (+ 1 2)
      ast = lst([id(:+), int(1), int(2)])

      assert {%AST.Call{
                callee: :+,
                args: [%AST.Literal{type: :Int, value: 1}, %AST.Literal{type: :Int, value: 2}]
              }, _new_env} =
               MacroExpander.expand(ast, env)
    end

    test "defmacro stores definition in Env" do
      env = Env.new(macro_engine: :interpreter)

      # (defmacro identity (x) x)
      macro_ast =
        lst([
          id(:defmacro),
          id(:identity),
          tup([id(:x)]),
          lst([id(:x)])
        ])

      assert {nil, new_env} = MacroExpander.expand(macro_ast, env)
      assert Env.has_macro?(new_env, :identity)

      macro_def = Env.get_macro(new_env, :identity)
      assert macro_def.name == :identity
      assert macro_def.args == [id(:x)]

      # Pruning check
      assert {[], _env} = MacroExpander.expand_list([macro_ast], env)
    end

    test "defmacro is removed from the AST after evaluated" do
      env = Env.new(macro_engine: :interpreter)

      # (defmacro identity (x) x)
      macro_ast =
        lst([
          id(:defmacro),
          id(:identity),
          tup([id(:x)]),
          lst([id(:x)])
        ])

      assert {[], _env} = MacroExpander.expand_list([macro_ast], env)
    end

    test "quote wraps its body without expanding inner nodes" do
      env = Env.new()
      # (quote (+ 1 2))
      ast = lst([id(:quote), lst([id(:+), int(1), int(2)])])

      assert {%AST.Quote{body: %AST.List{}}, _env} = MacroExpander.expand(ast, env)
    end
  end

  describe "Backend Integration" do
    test "macro invocation evaluated AST (Interpreter)" do
      env = Env.new(macro_engine: :interpreter)

      # (defmacro identity (x) x)
      macro_def = %AST.DefMacro{
        name: :identity,
        args: [id(:x)],
        body: [id(:x)]
      }

      env = Env.put_macro(env, :identity, macro_def)

      # (identity 42)
      call_ast = lst([id(:identity), int(42)])
      assert {%AST.Literal{type: :Int, value: 42}, _new_env} = MacroExpander.expand(call_ast, env)
    end

    test "defmacro uses BEAM CodeGen and caches the compiled function" do
      env = Env.new(macro_engine: :beam)

      # (defmacro identity (x) x)
      macro_ast =
        lst([
          id(:defmacro),
          id(:identity),
          tup([id(:x)]),
          lst([id(:x)])
        ])

      assert {nil, new_env} = MacroExpander.expand(macro_ast, env)
      cached_macro = Env.get_macro(new_env, :identity)
      assert {mod_atom, :identity} = cached_macro.compiled_fn
      assert is_atom(mod_atom)
    end
  end
end
