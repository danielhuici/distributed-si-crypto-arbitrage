defmodule Calculator.BasicStrategy do
	@behaviour Calculator
	def calculate(coin_values_map, calculator_handler_pid) do
		Enum.each(coin_values_map, fn({key, value}) ->
			if (value != %{}) do # Check if map values 
				map = cross_all_exchanges(Map.to_list(value), %{})
				IO.puts("Final MAP: #{inspect(map)}")
				send(calculator_handler_pid, {:new_calc, {key, map}})
			end
		end)
		coin_values_map
	end

	defp cross_all_exchanges(exchange_values_map, result_map) do # [Binance, Bitflinex, Coinbase] => Binance - Bitflinex, Binance - Coinbase, Bitflinex - Coinbase
		result_map = if length(exchange_values_map) > 1 do
			[exchange1 | tail] = exchange_values_map
			result_map = cross_two_exchanges(exchange1, tail, result_map)
			cross_all_exchanges(tail, result_map)
		else
			result_map
		end
		
	end

	defp cross_two_exchanges(exchange1, rest_exchanges, result_map) do
		result_map = if rest_exchanges != [] do
			{exchange_1, value1} = exchange1
			[{exchange2, value2} | tail] = rest_exchanges 
			IO.puts("Cross #{inspect(exchange_1)} --> #{inspect(exchange2)}")
			result_map = Map.put(result_map, String.to_atom("#{Atom.to_string(exchange_1)}-#{Atom.to_string(exchange2)}"), new_get_minmax_value(exchange_1, exchange2, value1, value2))
			IO.puts("Result map: #{inspect(result_map)}")
			cross_two_exchanges(exchange1, tail, result_map)
		else 
			result_map
		end
	end

	defp new_get_minmax_value(exchange1, exchange2, value1, value2) do
		value_map = if value1 < value2 do
			%{:min_exchange => exchange1,
			  :max_exchange => exchange2,
			  :min_value => value1,
			  :max_value => value2,
			  :profit => value2/value1}
		else
			%{:min_exchange => exchange2,
			  :max_exchange => exchange1,
			  :min_value => value2,
			  :max_value => value1,
			  :profit => value1/value2}
		end
		value_map
	end
	
end
