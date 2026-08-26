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

  def get_var(env, key), do: lookup(env, :vars, key)
  def get_macro(env, key), do: lookup(env, :macros, key)
  def get_type(env, key), do: lookup(env, :types, key)

  def put_var(env, key, val), do: %{env | vars: Map.put(env.vars, key, val)}
  def put_macro(env, key, val), do: %{env | macros: Map.put(env.macros, key, val)}
  def put_type(env, key, val), do: %{env | types: Map.put(env.types, key, val)}

  defp lookup(nil, _field, _key), do: nil

  defp lookup(env, field, key) do
    map = Map.fetch!(env, field)
    case Map.fetch(map, key) do
      {:ok, val} -> val
      :error -> lookup(env.parent, field, key)
    end
  end

end
