defmodule Core.AST do
  @moduledoc """
  Representação em memória de cada elemento da arvore de síntaxe abstrata.
  """
  # Top Level Module
  defmodule Module, do: defstruct([:name, :body, meta: %{}])

  # Literals
  defmodule Literal, do: defstruct([:value, :type, meta: %{}])
  defmodule Identifier, do: defstruct([:name, meta: %{}])
  defmodule List, do: defstruct([:elements, meta: %{}])
  defmodule Map, do: defstruct([:pairs, meta: %{}])
  defmodule Tuple, do: defstruct([:elements, meta: %{}])

  # Core, elementos que precisam existir no runtime
  defmodule Def, do: defstruct([:name, :body, meta: %{}])
  defmodule Fn, do: defstruct([:args, :body, meta: %{}])
  defmodule Let, do: defstruct([:bindings, :body, meta: %{}])
  defmodule If, do: defstruct([:condition, :then, :else, meta: %{}])
  defmodule Call, do: defstruct([:callee, :args, meta: %{}])
  defmodule FFI, do: defstruct([:module, :function, :args, meta: %{}])

  # Macros, essas estruturas vão ter comportamento definido no MacroExpander, não vão pra runtime
  defmodule DefMacro, do: defstruct([:name, :args, :body, meta: %{}])
  defmodule Quote, do: defstruct([:body, meta: %{}])
  defmodule Unquote, do: defstruct([:body, meta: %{}])
  defmodule Spread, do: defstruct([:expr, meta: %{}])
end
