defmodule Exchange.Binance do

    def operate(list_coin) do
		list_coin = if list_coin == [] do
			 ModelCrypto.get_cryptos(:binance)
		else
			list_coin
		end
		
		[coin | tail] = list_coin
		IO.puts("GO, BINANCE!: #{inspect(coin)}")
		url = "https://binance.com/api/v3/avgPrice?symbol=#{coin}"
		
		HTTPoison.start
		case HTTPoison.get(url, [], follow_redirect: true,
			hackney: [{:force_redirect, true}]) do
			{:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
				value = Float.parse(Jason.decode!(body)["price"])
				IO.puts("Ver valor binance: #{inspect(value)}")
				send({:calculator,:"calculator@127.0.0.1"}, {:new_value, {:binance, coin, elem(value,0)}})
			#{:ok, %HTTPoison.Response{status_code: 404}} ->
			#	IO.puts "Not found :("
			#{:error, %HTTPoison.Error{reason: reason}} ->
			#	IO.inspect reason
		end
		Process.sleep(2000)
		operate(tail)
	end
end
