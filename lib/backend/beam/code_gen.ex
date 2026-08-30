defmodule Backend.Beam.CodeGen do
  @moduledoc """
  Módulo responsável por gerar código BEAM a partir da AST tipada.
  """
  alias Core.AST

  def run(_typed_ast, env) do
    {:ok, [], env}
  end

  def compile_macro(%AST.DefMacro{} = macro_node, env) do
    unique_id = System.unique_integer([:positive])
    mod_name = String.to_atom("macro_#{macro_node.name}_#{unique_id}")

    macro_module = %AST.Module{
      name: mod_name,
      body: [macro_node],
      meta: macro_node.meta
    }

    {:ok, erl_ast, _env} = run(macro_module, env)
    {:ok, ^mod_name, bytecode} = :compile.forms(erl_ast, [:return_errors])

    {mod_name, bytecode}
  end
end
