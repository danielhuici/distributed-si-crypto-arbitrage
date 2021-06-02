defmodule Calculator.BasicStrategy do
	@behaviour Calculator
	def calculate(coin_values_map, calculator_handler_pid) do
		map = iterate_coins(Map.to_list(coin_values_map), %{})
		#IO.puts("Basic strategy: #{inspect(map)}")
		send(calculator_handler_pid, {:new_calc, {:basic, map}})
	end

	defp iterate_coins(coin_values_map, result_map) do
		if (List.first(coin_values_map) != nil) do
			[{coin, exchanges} | tail] = coin_values_map
			map = if (exchanges != %{}) do # Check if map values 
				cross_all_exchanges(Map.to_list(exchanges), %{})
			else 
				%{}
			end
			iterate_coins(tail, Map.put(result_map, coin, map))
		else
			result_map
		end
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
			{exchange_1, {value1, timestamp1}} = exchange1
			[{exchange2, {value2, timestamp2}} | tail] = rest_exchanges 
			#IO.puts("Crossing values with timestamps: #{inspect(timestamp1)} --> #{inspect(timestamp2)}")
			result_map = Map.put(result_map, String.to_atom("#{Atom.to_string(exchange_1)}-#{Atom.to_string(exchange2)}"), new_get_minmax_value(exchange_1, exchange2, value1, value2))
			#IO.puts("Result map: #{inspect(result_map)}")
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
