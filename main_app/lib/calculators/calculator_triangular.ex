defmodule Calculator.TriangularStrategy do
	@behaviour Calculator
	def calculate(coin_values_map, calculator_handler_pid) do
		Enum.each(coin_values_map, fn({key, value}) ->
			if (value != %{}) do # Check if map values 
				IO.puts("Triangular-strategy: #{inspect(key)} #{inspect(value)}")
				#send(calculator_handler_pid, {:new_calc, {"triangular", key, map}})
			end
		end)
		coin_values_map
	end

	
end
