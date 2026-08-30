defmodule Midfield.MacroExpander do
  @moduledoc "TODO: implementar MacroExpander"
  alias Core.Env
  alias Core.AST
  alias Core.AST.{List, Identifier, Tuple}

  def run(%AST.Module{body: trees} = root, env) do
    {expanded_trees, final_env} = expand_list(trees, env)
    {:ok, %AST.Module{root | body: expanded_trees}, final_env}
  end

  def expand_list(nodes, env) do
    {expanded_nodes, final_env} = Enum.map_reduce(nodes, env, &expand/2)
    filtered_nodes = Enum.reject(expanded_nodes, &is_nil/1)
    {filtered_nodes, final_env}
  end

  def expand(
        %List{
          elements: [
            %Identifier{name: :defmacro},
            %Identifier{name: macro_name},
            %Tuple{elements: args},
            %List{elements: body} | _
          ]
        } = node,
        env
      ) do
    macro_node =
      %AST.DefMacro{
        name: macro_name,
        args: args,
        body: body,
        meta: node.meta
      }
      |> then(fn node ->
        case env.opts[:macro_engine] do
          :beam ->
            {mod_name, bytecode} = Backend.Beam.CodeGen.compile_macro(node, env)
            Backend.Beam.Loader.load_bytecode(mod_name, bytecode)
            %{node | compiled_fn: {mod_name, macro_name}}

          _ ->
            node
        end
      end)

    new_env = Env.put_macro(env, macro_name, macro_node)
    {nil, new_env}
  end

  def expand(%List{elements: [%Identifier{name: :quote}, exp]} = node, env) do
    quoted_node = %AST.Quote{
      body: exp,
      meta: node.meta
    }

    {quoted_node, env}
  end

  def expand(%List{elements: [%Identifier{name: :unquote}, exp]} = node, env) do
    {expanded_exp, new_env} = expand(exp, env)

    unquoted_node = %AST.Unquote{
      body: expanded_exp,
      meta: node.meta
    }

    {unquoted_node, new_env}
  end

  def expand(%List{elements: [%Identifier{name: fn_name} | args]} = node, env) do
    if Env.has_macro?(env, fn_name) do
      apply_macro(fn_name, args, env) |> expand(env)
    else
      {expanded_args, new_env} = expand_list(args, env)
      {%AST.Call{callee: fn_name, args: expanded_args, meta: node.meta}, new_env}
    end
  end

  def expand(%List{elements: elements} = node, env) do
    {expanded_elements, new_env} = Enum.map_reduce(elements, env, &expand/2)
    {%AST.List{node | elements: expanded_elements}, new_env}
  end

  def expand(ast, env), do: {ast, env}

  def apply_macro(macro_name, call_args, parent_env) do
    macro_node = Env.get_macro(parent_env, macro_name)

    if length(macro_node.args) != length(call_args) do
      raise "Macro #{macro_name} expected #{length(macro_node.args)} arguments, got #{length(call_args)}"
    end

    case parent_env.opts[:macro_engine] do
      :beam ->
        {mod, fun} = macro_node.compiled_fn
        apply(mod, fun, [call_args, parent_env])

      _ ->
        bindings =
          macro_node.args
          |> Enum.map(fn %Identifier{name: name} -> name end)
          |> Enum.zip(call_args)
          |> Enum.into(%{})

        child_env = Env.new(parent_env) |> Env.put_vars(bindings)
        Backend.Interpreter.run(macro_node.body, child_env)
    end
  end
end
