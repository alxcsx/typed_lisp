defmodule CLI do
  def main(args) do
    {opts, files, _} =
      OptionParser.parse(
        args,
        switches: [repl: :boolean, compile: :boolean, target: :string]
      )

    mode = if opts[:compile], do: :compile, else: :interpret
    pipeline_opts = [mode: mode]

    cond do
      opts[:repl] -> REPL.start(pipeline_opts)
      length(files) > 0 -> run_file(hd(files), pipeline_opts)
      true -> IO.puts("Invalid Operation")
    end
  end

  defp run_file(file, opts) do
    with {:ok, source} <- File.read(file),
         {:ok, result, _env} <- Pipeline.run(source, opts) do
      IO.puts("=> #{inspect(result)}")
    else
      {:error, err} -> IO.puts("Compiler Error: #{err}")
    end
  end
end
