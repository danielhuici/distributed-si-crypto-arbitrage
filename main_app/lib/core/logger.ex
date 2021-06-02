defmodule DebugLogger do
    def print(text) do
        if (Application.fetch_env!(:tfg, :DEBUG) == "enable") do
            IO.puts(text)
        end
    end
end