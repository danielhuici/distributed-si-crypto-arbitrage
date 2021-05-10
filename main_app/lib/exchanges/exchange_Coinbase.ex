defmodule Exchange.Kraken do
    @behaviour Exchange
    
    @exchange :kraken
    @url "https://api.kraken.com/0/public/Ticker?pair="
    @request_time 5000

	def operate(list_coin) do
        list_coin = if List.first(list_coin) == nil do 
            [
            Exchange.Kraken.CoinFactory.new_coin("BTC_USD","BTCUSD"),
            Exchange.Kraken.CoinFactory.new_coin("ETH_BTC","ETHBTC"),
            Exchange.Kraken.CoinFactory.new_coin("LTC_BTC","LTCBTC"),
            Exchange.Kraken.CoinFactory.new_coin("ADA_BTC","ADABTC")
            ]
        else 
            list_coin
        end

        [coin | tail] = list_coin        

        HTTPoison.start()
		case HTTPoison.get("#{@url}#{Coin.get_concrete_name(coin)}", [], follow_redirect: true,
			hackney: [{:force_redirect, true}]) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> 
                result = Jason.decode!(body)
                value = elem(Float.parse(List.first(result["result"][List.first(Map.keys(result["result"]))]["a"])), 0)
                IO.puts("#{inspect(@exchange)}. Coin #{inspect(Coin.get_global_name(coin))} - #{inspect(Coin.get_concrete_name(coin))}. Value: #{inspect(value)}")
                send(NodeRepository.get_module_pid("calculator"), {:new_value, {@exchange, Coin.get_global_name(coin), value}})
        end
        Process.sleep(@request_time)
        operate(tail)
    end

    
end

defmodule Exchange.Kraken.CoinFactory do
    def new_coin(global_name, concrete_name) do
        Coin.create_coin(global_name, concrete_name)
    end
end

