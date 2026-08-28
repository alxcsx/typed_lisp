defmodule Parser.SyntaxAnalyzer do
  @moduledoc "TODO: implementar SyntaxAnalyzer"
  alias Core.AST

  def run(_tokens) do
    {:ok, %AST.Module{name: "random module", body: []}}
  end
end
