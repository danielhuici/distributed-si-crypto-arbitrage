defmodule Core.Calculator do
	@behaviour DistributedModule
	def init() do 
		handle_values(%{}, %{})
	end

	defp handle_values(coin_value_map, arbitrage_map) do
		receive do 
			{:new_value, {exchange, coin, value}} -> 
				#DebugLogger.print("[CALCULATOR] New value from #{inspect(exchange)} - #{inspect(coin)} with value: #{inspect(value)}")
				coin_value_map = if coin_value_map[String.to_atom(coin)] == nil do
					Map.put(coin_value_map, String.to_atom(coin), %{})
				else
					coin_value_map
				end
				map = Map.put(coin_value_map[String.to_atom(coin)], exchange, {value, DateTime.utc_now()})
				coin_value_map = Map.put(coin_value_map, String.to_atom(coin), map)
				call_strategies(Calculator.Model.get_strategy_lists(), coin_value_map)
				handle_values(coin_value_map, arbitrage_map)
			{:new_calc, {strategy, new_arbitrage_calc}} ->  
				#DebugLogger.print("[CALCULATOR] Got new data calculated for strategy ~ #{inspect(strategy)}")
				map = Map.put(arbitrage_map, strategy, new_arbitrage_calc)
				handle_values(coin_value_map,map)
			{:get_values, api_pid} -> 
				#DebugLogger.print("[CALCULATOR] Send calc data")
				send(api_pid, {:arbitrage_values, arbitrage_map})
				handle_values(coin_value_map, arbitrage_map)
			{:get_market, api_pid} ->
				send(api_pid, {:market_values, coin_value_map})
				handle_values(coin_value_map, arbitrage_map)
			
			_-> DebugLogger.print("[CALCULATOR] EXCEPTION! Unhandled call")
				handle_values(coin_value_map, arbitrage_map)

		end
	end

	def call_strategies(list_strategies, coin_value_map) do
		if list_strategies != [] do
			[strategy | tail] = list_strategies
			this_pid = self()
			#DebugLogger.print("[CALCULATOR] Calling strategy: #{inspect(strategy)}")
			spawn(fn -> strategy.calculate(coin_value_map, this_pid) end )
			call_strategies(tail, coin_value_map)
		end
	end
end