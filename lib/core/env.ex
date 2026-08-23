defmodule Core.Env do
  @moduledoc """
  Registro de variáveis, macros e futuramente tipos.
  Usado por todas as etapas do compilador pra saber o que existe no escopo atual
  """
  defstruct vars: %{},
            types: %{},
            macros: %{},
            parent: nil

  def new(parent \\ nil), do: %__MODULE__{parent: parent}

  def get_var(env, key) do
    case(Map.get(env.vars, key)) do
      nil -> if env.parent, do: get_var(env.parent, key), else: nil
      val -> val
    end
  end
end
