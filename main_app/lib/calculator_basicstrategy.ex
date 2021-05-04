defmodule Calculator.BasicStrategy do
	@behaviour Calculator
	def calculate(coin_values_map) do
		Enum.each(coin_values_map, fn({key, value}) ->
			if (value != %{}) do # Check if map has values yet
				{min_exchange, min_value} = get_min_value(value, Exchange.Model.get_exchange_list(), {:nil, 999999999}) #{exchange, value}
				{max_exchange, max_value} = get_max_value(value, Exchange.Model.get_exchange_list(), {:nil, 0}) #{exchange, value}
				result = max_value / min_value
				map = %{:min_exchange => min_exchange,
						:max_exchange => max_exchange,
						:min_value => min_value,
						:max_value => max_value,
						:profit => result}
				send(Nodes.get_pid(:calculator), {:new_calc, {key, map}})
			end
		end)
		coin_values_map
	end

	defp get_min_value(coin_values_map, [], min) do
		min
	end

	defp get_min_value(coin_values_map, exchange_list, min) do
		[exchange | tail] = exchange_list
		if coin_values_map[exchange] != nil && coin_values_map[exchange] < elem(min, 1) do
			get_min_value(coin_values_map, tail, {exchange, coin_values_map[exchange]})
		else 
			get_min_value(coin_values_map, tail, min)
		end
	end

	defp get_max_value(coin_values_map, [], max) do
		max
	end

	defp get_max_value(coin_values_map, exchange_list, max) do
		[exchange | tail] = exchange_list
		if coin_values_map[exchange] != nil && coin_values_map[exchange] >  elem(max, 1) do
			get_max_value(coin_values_map, tail, {exchange, coin_values_map[exchange]})
		else 
			get_max_value(coin_values_map, tail, max)
		end
	end

	
end
