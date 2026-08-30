defmodule Backend.Beam.Loader do
  def load_bytecode(mod_name, bytecode) do
    case :code.load_binary(mod_name, ~c"nofile", bytecode) do
      {:module, ^mod_name} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
