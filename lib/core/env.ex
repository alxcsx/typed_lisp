defmodule Core.Env do
  @moduledoc """
  Registro de variáveis, macros e futuramente tipos.
  Usado por todas as etapas do compilador pra saber o que existe no escopo atual
  """
  defstruct vars: %{},
            types: %{},
            macros: %{},
            opts: [],
            parent: nil

  def new(%Core.Env{} = parent), do: %Core.Env{parent: parent, opts: parent.opts}

  def new(opts) when is_list(opts) do
    engine = Keyword.get(opts, :macro_engine, :interpreter)
    %Core.Env{parent: nil, opts: [macro_engine: engine]}
  end

  def new(), do: new([])

  def get_var(env, key), do: lookup(env, :vars, key)
  def get_macro(env, key), do: lookup(env, :macros, key)
  def get_type(env, key), do: lookup(env, :types, key)

  def put_vars(env, new_vars), do: %{env | vars: Map.merge(env.vars, new_vars)}
  def put_var(env, key, val), do: %{env | vars: Map.put(env.vars, key, val)}
  def put_macro(env, key, val), do: %{env | macros: Map.put(env.macros, key, val)}
  def put_type(env, key, val), do: %{env | types: Map.put(env.types, key, val)}

  def has_var?(env, key), do: key_check(env, :vars, key)
  def has_macro?(env, key), do: key_check(env, :macros, key)
  def has_type?(env, key), do: key_check(env, :types, key)
  def has_parent?(env), do: env.parent != nil

  defp key_check(nil, _field, _key), do: false

  defp key_check(env, field, key) when is_atom(key) do
    map = Map.fetch!(env, field)
    Map.has_key?(map, key) or key_check(env.parent, field, key)
  end

  defp lookup(nil, _field, _key), do: nil

  defp lookup(env, field, key) do
    map = Map.fetch!(env, field)

    case Map.fetch(map, key) do
      {:ok, val} -> val
      :error -> lookup(env.parent, field, key)
    end
  end
end
