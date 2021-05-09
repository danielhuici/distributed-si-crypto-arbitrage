defmodule Core.Calculator do
	@behaviour DistributedModule
	def init() do 
		init_coin_map = create_map(ModelCrypto.get_crypto_list(), %{})
        IO.puts("Init map: #{inspect(init_coin_map)}")
		handle_values(init_coin_map, %{})
	end


	defp create_map(cryptos, map) do 
		map = if List.first(cryptos) != nil do
			[coin | tail] = cryptos
			map = Map.put(map, coin.crypto, %{})
			create_map(tail, map)
		else 
			map
		end
		map
	end

	defp handle_values(coin_value_map, arbitrage_map) do
		receive do 
			{:new_value, {exchange, coin, value}} -> IO.puts("[CALCULATOR] New value from #{inspect(exchange)} - #{inspect(coin)} with value: #{inspect(value)}")
													map = Map.put(coin_value_map[String.to_atom(coin)], exchange, value)
													coin_value_map = Map.put(coin_value_map, String.to_atom(coin), map)
													call_strategies(Calculator.Model.get_strategy_lists(), coin_value_map)
													handle_values(coin_value_map, arbitrage_map)
			{:new_calc, {coin, new_arbitrage_calc}} ->  IO.puts("[CALCULATOR] Got new data calculated for coin #{inspect(coin)}: #{inspect(new_arbitrage_calc)}")
														IO.puts("[STATUS] #{inspect(arbitrage_map)}")
														handle_values(coin_value_map, Map.put(arbitrage_map, coin, new_arbitrage_calc))
			{:get_values, api_pid} -> IO.puts("[CALCULATOR] Send data to Web server")
									  send(api_pid, {:arbitrage_values, arbitrage_map})
									  handle_values(coin_value_map, arbitrage_map)
			
			_-> IO.puts("CALCULATOR: Error. Valor de recepción no controlado")

		end
	end

	def call_strategies(list_strategies, coin_value_map) do
		if list_strategies != [] do
			[strategy | tail] = list_strategies
			strategy.calculate(coin_value_map)
			call_strategies(tail, coin_value_map)
		end
	end
end