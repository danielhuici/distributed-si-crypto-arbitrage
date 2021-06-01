defmodule Exchange.Binance do
	@behaviour Exchange

	@exchange :binance
    @url "https://binance.com/api/v3/avgPrice?symbol="
    @request_time 1000

    def operate(list_coin, calculator_handler_pid) do
		list_coin = if list_coin == [] do
			[
			Exchange.Binance.CoinFactory.new_coin("BTC_USD","BTCUSDT"),
			Exchange.Binance.CoinFactory.new_coin("ETH_BTC","ETHBTC"),
			Exchange.Binance.CoinFactory.new_coin("LTC_BTC","LTCBTC"),
			Exchange.Binance.CoinFactory.new_coin("ADA_BTC","ADABTC"),

			Exchange.Kraken.CoinFactory.new_coin("ETH_USD","ETHUSDT"),
            Exchange.Kraken.CoinFactory.new_coin("LTC_USD","LTCUSDT"),
            Exchange.Kraken.CoinFactory.new_coin("ADA_USD","ADAUSDT")
			]
		else
			list_coin
		end
		
		[coin | tail] = list_coin
		
		HTTPoison.start()
		case HTTPoison.get("#{@url}#{Coin.get_concrete_name(coin)}", [], follow_redirect: true,
			hackney: [{:force_redirect, true}]) do
			{:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
				value = Float.parse(Jason.decode!(body)["price"])
				IO.puts("#{inspect(@exchange)}. Coin #{inspect(Coin.get_global_name(coin))} - #{inspect(Coin.get_concrete_name(coin))}. Value: #{inspect(value)}")
				send(calculator_handler_pid, {:new_value, {@exchange, Coin.get_global_name(coin), elem(value,0)}})
			_ -> IO.puts("Error while requesting #{inspect(@exchange)}. Wait & try again...")
				Process.sleep(30000)
			#	IO.puts "Not found :("
			#{:error, %HTTPoison.Error{reason: reason}} ->
			#	IO.inspect reason
		end

		Process.sleep(@request_time)
		operate(tail, calculator_handler_pid)
	end

	
end

defmodule Exchange.Binance.CoinFactory do
	def new_coin(global_name, concrete_name) do
		Coin.create_coin(global_name, concrete_name)
	end
end