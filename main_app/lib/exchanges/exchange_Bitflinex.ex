defmodule Exchange.Bitfinex do
    @behaviour Exchange
    
    @exchange :bitflinex
    @url "https://api.bitfinex.com/v2/calc/trade/avg"
    @request_time 1000

	def operate(list_coin, calculator_handler_pid) do
        list_coin = if List.first(list_coin) == nil do 
            [
            Exchange.Bitfinex.CoinFactory.new_coin("BTC_USD","BTCUSD"),
            Exchange.Bitfinex.CoinFactory.new_coin("ETH_BTC","ETHBTC"),
            Exchange.Bitfinex.CoinFactory.new_coin("LTC_BTC","LTCBTC"),
            Exchange.Bitfinex.CoinFactory.new_coin("ADA_BTC","ADABTC"),

            Exchange.Kraken.CoinFactory.new_coin("ETH_USD","ETHUSD"),
            Exchange.Kraken.CoinFactory.new_coin("LTC_USD","LTCUSD"),
            Exchange.Kraken.CoinFactory.new_coin("ADA_USD","ADAUSD")
            ]
        else 
            list_coin
        end

        [coin | tail] = list_coin        

        body_params = Jason.encode!(%{"symbol" => "t#{Coin.get_concrete_name(coin)}", "amount" => "100"})
        HTTPoison.start()
        http_response = HTTPoison.post(@url, body_params, %{"Content-Type" => "application/json"}) 
        case http_response do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> 
                value = List.first(Jason.decode!(body))
                IO.puts("#{inspect(@exchange)}. Coin #{inspect(Coin.get_global_name(coin))} - #{inspect(Coin.get_concrete_name(coin))}. Value: #{inspect(value)}")
                send(calculator_handler_pid, {:new_value, {@exchange, Coin.get_global_name(coin), value}})
            _ -> IO.puts("Error while requesting #{inspect(@exchange)}. Wait & try again...")
				Process.sleep(30000)
        end
        Process.sleep(@request_time)
        operate(tail, calculator_handler_pid)
    end

    
end

defmodule Exchange.Bitfinex.CoinFactory do
    def new_coin(global_name, concrete_name) do
        Coin.create_coin(global_name, concrete_name)
    end
end
