defmodule Calculator.BasicStrategy do
	@behaviour Calculator
	def calculate(coin_values_map) do
		Enum.each(coin_values_map, fn({key, value}) ->
			if (value != %{}) do # Check if map values 
				map = cross_all_exchanges(Map.to_list(value), %{})
				send(Nodes.get_pid(:calculator), {:new_calc, {key, map}})
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

	defp cross_two_exchanges(exchange1, list_exchange, result_map) do
		result_map = if list_exchange != [] do
			{exchange1, value1} = exchange1
			[{exchange2, value2} | tail] = list_exchange 
			result_map = Map.put(result_map, String.to_atom("#{Atom.to_string(exchange1)}-#{Atom.to_string(exchange2)}"), new_get_minmax_value(exchange1, exchange2, value1, value2))
			cross_two_exchanges(exchange1, tail, result_map)
			result_map
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
