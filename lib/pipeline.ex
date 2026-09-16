defmodule Pipeline do
  @moduledoc """
  Modulo principal que orquestra toda a compilação.
  """
  alias Core.Env

  def run(source, opts \\ []) do
    mode = Keyword.get(opts, :mode, :interpret)
    env = Keyword.get(opts, :env, Env.new())

    # Pipeline de arquivo:
    with {:ok, tokens} <- Parser.Lexer.run(source),
         {:ok, tree_list} <- Parser.SyntaxAnalyzer.run(tokens),
         {:ok, modules, env} <- identify_modules(tree_list, env) do
      compile_modules(modules, mode, env)
    end
  end

  defp run_backend(:interpret, ast, env), do: Backend.Interpreter.run(ast, env)
  defp run_backend(:compile, ast, env), do: Backend.CodeGen.run(ast, env)

  # --  Helpers
  defp compile_modules(modules, mode, env) do
    Enum.reduce_while(modules, {:ok, [], env}, fn module, {:ok, results, env} ->
      case compile_module(module, mode, env) do
        {:ok, result, env} -> {:cont, {:ok, [result | results], env}}
      end
    end)
  end

  def compile_module(module, mode, env) do
    module_env = %{env | current_module: module.name}

    with {:ok, expanded_ast, module_env} <- Midfield.MacroExpander.run(module, module_env),
         {:ok, typed_ast, module_env} <- Midfield.TypeChecker.run(expanded_ast, module_env),
         {:ok, result, module_env} <- run_backend(mode, typed_ast, module_env) do
      # TODO: add result to global_env.modules
      {:ok, result, module_env}
    end
  end

  defp identify_modules(tree_list, env) do
    alias Core.AST.{List, Module, Identifier}

    {inner_modules_raw, loose_expressions} =
      tree_list
      |> Enum.split_with(fn
        %List{elements: [%Identifier{name: :"def-module"} | _]} -> true
        _ -> false
      end)

    inner_modules =
      inner_modules_raw
      |> Enum.map(fn %List{elements: [_defmodule, %Identifier{name: name}, body], meta: meta} ->
        %Module{name: name, body: body, meta: meta}
      end)

    modules =
      case loose_expressions do
        [] ->
          inner_modules

        _ ->
          inner_modules ++ [%Module{name: :__main__, body: loose_expressions, meta: %{line: 0}}]
      end

    {:ok, modules, env}
  end
end
