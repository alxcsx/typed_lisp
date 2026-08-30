formatters =
  if System.get_env("CI") do
    [JUnitFormatter]
  else
    [ExUnit.CLIFormatter]
  end

ExUnit.configure(exclude: [:nice_to_have])
ExUnit.start(formatters: formatters)
