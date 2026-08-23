defmodule Pipeline do
  @moduledoc """
  Modulo principal que orquestra toda a compilação.
  """
  alias Core.Env

  def run(source, opts \\ []) do
    mode = Keyword.get(opts, :mode, :interpret)
    env = Keyword.get(opts, :env, Env.new())

    with {:ok, tokens} <- Parser.Lexer.run(source),
         {:ok, raw_ast} <- Parser.SyntaxAnalyzer.run(tokens),
         {:ok, expanded_ast, env} <- Midfield.MacroExpander.run(raw_ast, env),
         {:ok, typed_ast, env} <- Midfield.TypeChecker.run(expanded_ast, env),
         {:ok, result, env} <- run_backend(mode, typed_ast, env) do
      {:ok, result, env}
    end
  end

  defp run_backend(:interpret, ast, env), do: Backend.Interpreter.run(ast, env)
  defp run_backend(:compile, ast, env), do: Backend.CodeGen.run(ast, env)
end
