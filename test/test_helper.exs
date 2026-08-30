formatters = [ExUnit.CLIFormatter]

formatters =
  if System.get_env("CI") do
    [JUnitFormatter | formatters]
  else
    formatters
  end

ExUnit.configure(exclude: [:nice_to_have])
ExUnit.start(formatters: formatters)
