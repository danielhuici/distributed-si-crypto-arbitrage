defmodule Calculator.TriangularStrategy do
	@behaviour Calculator
	def calculate(coin_values_map, calculator_handler_pid) do
		#IO.puts("Triangular-strategy: #{inspect(coin_values_map)}")
		
		receiver = spawn(fn -> receive_values(%{}, calculator_handler_pid) end)
		btc_usd_values = find_BTC_USD_values(coin_values_map) # []
		iterate_coins(Map.to_list(coin_values_map), Map.to_list(coin_values_map), receiver)
	end

	def receive_values(map, calculator_handler_pid) do
		IO.puts("Receiver ok")
		receive do
			{:new_cross, coin, triangled_map} ->
				receive_values(Map.put(map, coin, triangled_map))
			{:end} -> send(calculator_handler_pid, {:new_calc, {"triangular", coin, triangled_map}})
		end
	end

	defp iterate_coins(initial_coin_value_map, coin_value_map, receiver) do
		if List.first(coin_value_map) != nil do
			[{coin, exchanges_values} | tail] = coin_value_map # [{"LTC_BTC", exchanges}, ...]
			if (coin != "BTC_USD" and Coin.get_second_coin(coin) != "USD") do
				btc_usd = find_BTC_USD_values(initial_coin_value_map)
				x_usd = find_x_USD_values(Coin.get_first_coin(coin) , initial_coin_value_map)
				if x_usd != nil and btc_usd != nil do
					#IO.puts("Veamos: #{inspect(exchanges_values)}")
					iterate_x_btc(Map.to_list(exchanges_values), Map.to_list(btc_usd), Map.to_list(x_usd), coin, receiver)
				end
				#IO.puts("Coin ENTRO!: #{coin} ~ #{inspect(x_usd)}")
			end
			iterate_coins(initial_coin_value_map, tail, receiver)
		end
	end

	# First-level iteration (X_BTC)
	defp iterate_x_btc(exchanges_values, btc_usd, usd_x, coin, receiver) do # [{"exchange" : value}, ...]
		if List.first(exchanges_values) != nil do
			[x_btc | tail] = exchanges_values 
			{exchange, value} = x_btc
			#IO.puts("PRIMER NIVEL: CRUZAR (X_BTC) #{inspect(coin)} - #{inspect(exchange)} - #{inspect(value)} === con === \n #{inspect(btc_usd)} y #{inspect(usd_x)}")
			iterate_btc_usd(btc_usd, usd_x, x_btc, coin, receiver)
			iterate_x_btc(tail, btc_usd, usd_x, coin, receiver)
		end
	end

	# Second-level iteration (BTC_USD)
	defp iterate_btc_usd(btc_usd, usd_x, x_btc_tuple, coin, receiver) do
		if (List.first(btc_usd) != nil) do
			[btc_usd_tuple | tail] = btc_usd
			{exchange, value} = btc_usd_tuple
			#IO.puts("SEGUNDO NIVEL: CRUZAR (BTC_USD) #{inspect(coin)} - #{inspect(exchange)} - #{inspect(value)} === con === \n (X_BTC) #{inspect(x_btc_tuple)} y (USD_X) #{inspect(usd_x)}")
			iterate_usd_x(btc_usd_tuple, usd_x, x_btc_tuple, coin, receiver)
			iterate_btc_usd(tail, usd_x, x_btc_tuple, coin, receiver)
		end
	end

	# Third-level iteration (USD_X)
	def iterate_usd_x(btc_usd_tuple, usd_x, x_btc_tuple, coin, receiver) do
		if (List.first(usd_x) != nil) do
			[usd_x_tuple | tail] = usd_x
			{exchange, value} = usd_x_tuple
			#IO.puts("TERCER NIVEL: CRUZAR (USD_X) #{inspect(coin)} - #{inspect(exchange)} - #{inspect(value)} === con === \n (X_BTC) #{inspect(x_btc_tuple)} y (BTC_USD) #{inspect(btc_usd_tuple)}")
			make_triangle(btc_usd_tuple, usd_x_tuple, x_btc_tuple, coin, receiver)
			iterate_usd_x(btc_usd_tuple, tail, x_btc_tuple, coin, receiver)
		end
	end


	def make_triangle(btc_usd, usd_x, x_btc, coin, receiver) do
		{btc_usd_exchange, btc_usd_value} = btc_usd
		{usd_x_exchange, usd_x_value} = usd_x
		{x_btc_exchange, x_btc_value} = x_btc
		
		profit = usd_x_value / (x_btc_value * btc_usd_value)
		profit = if profit < 1 do
			profit = 1/profit
		else 
			profit
		end
		

		map = %{String.to_atom("#{btc_usd_exchange}-#{usd_x_exchange}-#{x_btc_exchange}") => 
				%{
					btc_usd_exchange => btc_usd_value,
					usd_x_exchange => usd_x_value,
					x_btc_exchange => x_btc_value,
					:profit => profit 
				}
		}
				
		#IO.puts("El MAP: #{inspect(map)}")
		send(receiver, {:new_cross, coin, map})
	end


	defp find_x_USD_values(coin, coin_value_map) do # %{exchange: value, exchage: value ...}
		x_USD = "#{coin}_USD"
		coin_value_map[String.to_atom(x_USD)]
	end

	defp find_BTC_USD_values(coin_value_map) do # %{exchange: value, exchage: value ...}
		coin_value_map[:BTC_USD]
	end	
	
end