defmodule Parser.Lexer do
  @moduledoc """
  Analisador léxico: código-fonte vira uma lista plana de tokens.

  Formato dos tokens:

      {:"(", linha}                    estruturais: ( ) [ ] { }
      {:integer,    linha, 42}
      {:float,      linha, 3.14}
      {:string,     linha, "texto"}
      {:symbol,     linha, :chave}     vindo de  :chave
      {:identifier, linha, "nome"}     vira átomo no SyntaxAnalyzer
  """

  # Caracteres que encerram um número, identificador ou keyword.
  # Tudo que não está aqui pode compor um nome: por isso
  # `is-empty?`, `+`, `<=`, `*global-var*` são identificadores válidos.
  @delimiters [?(, ?), ?[, ?], ?{, ?}, ?", ?;, ?\s, ?\t, ?\r, ?\n]

  @doc "Recebe o código-fonte, devolve {:ok, tokens}."
  def run(source) when is_binary(source) do
    tokens =
      source
      |> String.to_charlist()
      |> scan(1, [])

    {:ok, tokens}
  end

  # -----------------------------------------------------------------
  # scan/3 — (caracteres_restantes, linha_atual, tokens_acumulados)
  #
  # Tokens são acumulados ao contrário (prepend é barato numa lista
  # ligada) e revertidos no fim.
  # -----------------------------------------------------------------

  defp scan([], _line, tokens) do
    Enum.reverse(tokens)
  end

  defp scan([?\n | rest], line, tokens) do
    scan(rest, line + 1, tokens)
  end

  defp scan([char | rest], line, tokens) when char in [?\s, ?\t, ?\r] do
    scan(rest, line, tokens)
  end

  # Comentário: ';' consome até a quebra de linha (que sobra e é
  # tratada pela cláusula acima, mantendo a contagem certa).
  defp scan([?; | rest], line, tokens) do
    remaining = Enum.drop_while(rest, fn char -> char != ?\n end)
    scan(remaining, line, tokens)
  end

  # Estruturais. Viram tuplas de 2 elementos, sem valor.
  defp scan([?( | rest], line, tokens), do: scan(rest, line, [{:"(", line} | tokens])
  defp scan([?) | rest], line, tokens), do: scan(rest, line, [{:")", line} | tokens])
  defp scan([?[ | rest], line, tokens), do: scan(rest, line, [{:"[", line} | tokens])
  defp scan([?] | rest], line, tokens), do: scan(rest, line, [{:"]", line} | tokens])
  defp scan([?{ | rest], line, tokens), do: scan(rest, line, [{:"{", line} | tokens])
  defp scan([?} | rest], line, tokens), do: scan(rest, line, [{:"}", line} | tokens])

  # String.
  defp scan([?" | rest], line, tokens) do
    {text, remaining} = read_string(rest, [], line)
    scan(remaining, line, [{:string, line, text} | tokens])
  end

  # Keyword: ':' seguido de um nome. O ':' é descartado.
  defp scan([?: | rest], line, tokens) do
    {word, remaining} = read_word(rest, [])

    if word == [] do
      raise "':' sozinho na linha #{line}: faltou o nome da keyword"
    end

    atom = word |> List.to_string() |> String.to_atom()
    scan(remaining, line, [{:symbol, line, atom} | tokens])
  end

  # Qualquer outra coisa: número ou identificador.
  # Todo delimitador já foi tratado acima, então `word` nunca vem
  # vazia aqui (se viesse, isto seria um laço infinito).
  defp scan(chars, line, tokens) do
    {word, remaining} = read_word(chars, [])
    scan(remaining, line, [classify(word, line) | tokens])
  end

  # -----------------------------------------------------------------
  # read_string/3 — consome até a aspa de fechamento.
  # -----------------------------------------------------------------

  defp read_string([], _acc, line) do
    raise "string não fechada, aberta na linha #{line}"
  end

  defp read_string([?\\, ?n | rest], acc, line), do: read_string(rest, [?\n | acc], line)
  defp read_string([?\\, ?t | rest], acc, line), do: read_string(rest, [?\t | acc], line)
  defp read_string([?\\, ?" | rest], acc, line), do: read_string(rest, [?" | acc], line)
  defp read_string([?\\, ?\\ | rest], acc, line), do: read_string(rest, [?\\ | acc], line)

  defp read_string([?" | rest], acc, _line) do
    {acc |> Enum.reverse() |> List.to_string(), rest}
  end

  defp read_string([char | rest], acc, line) do
    read_string(rest, [char | acc], line)
  end

  # -----------------------------------------------------------------
  # read_word/2 — consome caracteres até achar um delimitador.
  # -----------------------------------------------------------------

  defp read_word([], acc) do
    {Enum.reverse(acc), []}
  end

  defp read_word([char | rest], acc) do
    if char in @delimiters do
      # Devolve o delimitador para a entrada: scan/3 cuida dele.
      {Enum.reverse(acc), [char | rest]}
    else
      read_word(rest, [char | acc])
    end
  end

  # -----------------------------------------------------------------
  # classify/2 — número ou identificador?
  #
  # A ordem importa: "3" passa no teste de inteiro; "3.14" falha nele
  # (Integer.parse para no ponto e sobra ".14") e passa no de float.
  # "-" sozinho falha nos dois e vira identificador, que é o certo.
  # -----------------------------------------------------------------

  defp classify(word, line) do
    text = List.to_string(word)

    cond do
      integer?(text) -> {:integer, line, String.to_integer(text)}
      float?(text) -> {:float, line, String.to_float(text)}
      true -> {:identifier, line, text}
    end
  end

  # Integer.parse devolve {numero, resto}. Só é inteiro puro se o
  # resto for a string vazia.
  defp integer?(text) do
    case Integer.parse(text) do
      {_number, ""} -> true
      _ -> false
    end
  end

  defp float?(text) do
    case Float.parse(text) do
      {_number, ""} -> true
      _ -> false
    end
  end
end
