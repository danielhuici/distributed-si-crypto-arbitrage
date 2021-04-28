defmodule Exchange.Bitfinex do
	def operate(list_coin) do
        IO.puts("Al principio!: #{inspect(list_coin)}")
        list_coin = if List.first(list_coin) == nil do 
            list_coin = ModelCrypto.get_cryptos(:bitfinex)
        else 
            list_coin
        end

        IO.puts("Un poco despues...: #{inspect(list_coin)}")
        [coin | tail] = list_coin
        IO.puts("VAMOS, BITFINEX!: #{inspect(coin)}")
        

        url = "https://api.bitfinex.com/v2/calc/trade/avg"
        body_params = Jason.encode!(%{"symbol" => "t#{coin}", "amount" => "100"})
        HTTPoison.start
        http_response = HTTPoison.post(url, body_params, %{"Content-Type" => "application/json"}) 
        case http_response do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> 
                value = List.first(Jason.decode!(body))
                send({:calculator,:"calculator@127.0.0.1"}, {:new_value, {:bitfinex, coin, value}})
        end
        Process.sleep(2000)
        IO.puts("Vamos a la siguiente: #{inspect(tail)}")
        operate(tail)
    end
end
