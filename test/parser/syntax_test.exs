defmodule SyntaxTest do
  use ExUnit.Case, async: true
  alias Core.AST
  alias Core.AST.{Literal, Identifier, List, Tuple, Map}

  defp parse!(code) do
    {:ok, tokens} = Parser.Lexer.run(code)
    {:ok, raw_ast} = Parser.SyntaxAnalyzer.run(tokens)
    raw_ast
  end

  defp parse_error!(code) do
    {:ok, tokens} = Parser.Lexer.run(code)
    Parser.SyntaxAnalyzer.run(tokens)
  end

  describe "Literals" do
    test "parses integers and floats" do
      assert %AST.Module{body: [%Literal{type: :Int, value: 123}]} = parse!("123")
      assert %AST.Module{body: [%Literal{type: :Int, value: -42}]} = parse!("-42")
      assert %AST.Module{body: [%Literal{type: :Float, value: 3.14}]} = parse!("3.14")
      assert %AST.Module{body: [%Literal{type: :Float, value: -0.001}]} = parse!("-0.001")
    end

    test "parses strings" do
      assert %AST.Module{body: [%Literal{type: :Str, value: "hello world"}]} =
               parse!("\"hello world\"")
    end

    test "parse strings with escape sequences" do
      assert %AST.Module{body: [%Literal{type: :Str, value: "\"hello\""}]} =
               parse!("\"\\\"hello\\\"\"")

      assert %AST.Module{body: [%Literal{type: :Str, value: "line 1\nline 2"}]} =
               parse!("\"line 1\\nline 2\"")
    end

    test "parses keywords" do
      assert %AST.Module{body: [%Literal{type: :Key, value: :status}]} = parse!(":status")
      assert %AST.Module{body: [%Literal{type: :Key, value: :"is-valid?"}]} = parse!(":is-valid?")

      assert %AST.Module{body: [%Literal{type: :Key, value: :"*global-config*"}]} =
               parse!(":*global-config*")

      assert %AST.Module{body: [%Literal{type: :Key, value: :"123"}]} = parse!(":123")
    end
  end

  describe "Identifiers" do
    test "parses standard symbols" do
      assert %AST.Module{body: [%Identifier{name: :foo}]} = parse!("foo")
    end

    test "parses lisp-specific operators and characters" do
      assert %AST.Module{body: [%Identifier{name: :+}]} = parse!("+")
      assert %AST.Module{body: [%Identifier{name: :<=}]} = parse!("<=")

      assert %AST.Module{body: [%Identifier{name: :"is-empty?"}]} = parse!("is-empty?")
      assert %AST.Module{body: [%Identifier{name: :update!}]} = parse!("update!")
      assert %AST.Module{body: [%Identifier{name: :"*global-var*"}]} = parse!("*global-var*")
      assert %AST.Module{body: [%Identifier{name: :"my-var"}]} = parse!("my-var")
    end
  end

  describe "Collections" do
    test "parses lists" do
      assert %AST.Module{
               body: [
                 %List{
                   elements: [
                     %Identifier{name: :+},
                     %Literal{type: :Int, value: 1},
                     %Literal{type: :Int, value: 2}
                   ]
                 }
               ]
             } = parse!("(+ 1 2)")
    end

    test "parses tuples" do
      assert %AST.Module{
               body: [
                 %Tuple{
                   elements: [
                     %Identifier{name: :a},
                     %Literal{type: :Int, value: 10}
                   ]
                 }
               ]
             } = parse!("[a 10]")
    end

    test "parses maps with pairs" do
      assert %AST.Module{
               body: [
                 %Map{
                   pairs: [
                     {%Literal{type: :Key, value: :a}, %Literal{type: :Int, value: 1}},
                     {%Literal{type: :Key, value: :b}, %Literal{type: :Int, value: 2}}
                   ]
                 }
               ]
             } = parse!("{ :a 1 :b 2 }")
    end

    test "parses nested structures" do
      assert %AST.Module{
               body: [
                 %List{
                   elements: [
                     %Identifier{name: :def},
                     %Identifier{name: :"my-map"},
                     %Map{
                       pairs: [
                         {%Literal{type: :Key, value: :coords},
                          %Tuple{
                            elements: [
                              %Literal{type: :Int, value: 0},
                              %Literal{type: :Int, value: 0}
                            ]
                          }}
                       ]
                     }
                   ]
                 }
               ]
             } = parse!("(def my-map {:coords [0 0]})")
    end
  end

  describe "Not Required, But Cool" do
    @tag :nice_to_have
    test "custom syntax for maps" do
      assert %AST.Module{
               body: [
                 %Map{
                   pairs: [
                     {%Literal{type: :Key, value: :a}, %Literal{type: :Int, value: 1}},
                     {%Literal{type: :Key, value: :b}, %Literal{type: :Int, value: 2}}
                   ]
                 }
               ]
             } = parse!("{ a: 1 b: 2 }")
    end
  end

  describe "Line Metadata" do
    test "injects line numbers correctly" do
      code = """
      (def a 1)
      (+ a 2)
      """

      assert %AST.Module{
               body: [
                 %List{meta: %{line: 1}},
                 %List{meta: %{line: 2}}
               ]
             } = parse!(code)
    end
  end
end
