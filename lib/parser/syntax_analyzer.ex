defmodule Parser.SyntaxAnalyzer do
  @moduledoc """
  Analisador sintático: tokens viram AST bruta.

  Produz APENAS os nós de dados — Literal, Identifier, List, Tuple e
  Map — dentro de um AST.Module. Não sabe o que é `def`, `if` ou `fn`:
  para ele, `(def a 1)` é só uma lista com três elementos. Reconhecer
  formas especiais é trabalho do Midfield.
  """

  alias Core.AST
  alias Core.AST.{Literal, Identifier, Tuple}

  @doc "Recebe os tokens do Lexer, devolve {:ok, %AST.Module{}}."
  def run(tokens) do
    forms = parse_all(tokens, [])
    {:ok, %AST.Module{name: "main", body: forms, meta: %{line: 1}}}
  rescue
    error in RuntimeError -> {:error, error.message}
  end

  # -----------------------------------------------------------------
  # parse_all/2 — lê formas até acabarem os tokens.
  # -----------------------------------------------------------------

  defp parse_all([], forms) do
    Enum.reverse(forms)
  end

  defp parse_all(tokens, forms) do
    {form, rest} = parse_form(tokens)
    parse_all(rest, [form | forms])
  end

  # -----------------------------------------------------------------
  # parse_form/1 — lê UMA forma.
  #
  # Devolve {nó, tokens_que_sobraram}. Esse é o truque central: como
  # não existe variável mutável, em vez de mover um ponteiro global
  # cada função devolve o que ainda não consumiu.
  # -----------------------------------------------------------------

  # (a b c) -> List
  defp parse_form([{:"(", line} | rest]) do
    {elements, remaining} = parse_until(rest, :")", [])
    {%AST.List{elements: elements, meta: %{line: line}}, remaining}
  end

  # [a b] -> Tuple
  defp parse_form([{:"[", line} | rest]) do
    {elements, remaining} = parse_until(rest, :"]", [])
    {%Tuple{elements: elements, meta: %{line: line}}, remaining}
  end

  # {:a 1 :b 2} -> Map
  defp parse_form([{:"{", line} | rest]) do
    {elements, remaining} = parse_until(rest, :"}", [])
    {%AST.Map{pairs: to_pairs(elements, line), meta: %{line: line}}, remaining}
  end

  # Fechamento sem abertura correspondente.
  defp parse_form([{closer, line} | _rest]) when closer in [:")", :"]", :"}"] do
    raise "'#{closer}' inesperado na linha #{line}"
  end

  # Átomos.
  defp parse_form([{:integer, line, value} | rest]) do
    {%Literal{type: :Int, value: value, meta: %{line: line}}, rest}
  end

  defp parse_form([{:float, line, value} | rest]) do
    {%Literal{type: :Float, value: value, meta: %{line: line}}, rest}
  end

  defp parse_form([{:string, line, value} | rest]) do
    {%Literal{type: :Str, value: value, meta: %{line: line}}, rest}
  end

  defp parse_form([{:symbol, line, value} | rest]) do
    {%Literal{type: :Key, value: value, meta: %{line: line}}, rest}
  end

  # O Lexer entrega o nome como string; aqui vira átomo.
  defp parse_form([{:identifier, line, name} | rest]) do
    {%Identifier{name: String.to_atom(name), meta: %{line: line}}, rest}
  end

  defp parse_form([]) do
    raise "fim inesperado do arquivo: alguma expressão não foi fechada"
  end

  # -----------------------------------------------------------------
  # parse_until/3 — lê formas até achar o token de fechamento.
  # -----------------------------------------------------------------

  defp parse_until([], closer, _elements) do
    raise "fim inesperado do arquivo: faltou '#{closer}'"
  end

  defp parse_until([{closer, _line} | rest], closer, elements) do
    {Enum.reverse(elements), rest}
  end

  defp parse_until(tokens, closer, elements) do
    {form, remaining} = parse_form(tokens)
    parse_until(remaining, closer, [form | elements])
  end

  # -----------------------------------------------------------------
  # to_pairs/2 — os elementos de um Map vêm achatados
  # (chave, valor, chave, valor...). Aqui viram tuplas de dois.
  # -----------------------------------------------------------------

  defp to_pairs(elements, line) do
    if rem(length(elements), 2) != 0 do
      raise "map com número ímpar de elementos na linha #{line}"
    end

    elements
    |> Enum.chunk_every(2)
    |> Enum.map(fn [key, value] -> {key, value} end)
  end
end
