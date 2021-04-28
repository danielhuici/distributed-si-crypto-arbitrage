defmodule ModelCrypto do
    @crypto_list [
        %{:crypto => :BTC_USD, :binance => "BTCUSDT", :bitfinex => "BTCUSD"}, # BTC/USD
        %{:crypto => :ETH_BTC, :binance => "ETHBTC", :bitfinex => "ETHBTC"}, # ETHBTC
        %{:crypto => :LTC_BTC, :binance => "LTCBTC", :bitfinex => "LTCBTC"}, # LTCBTC
        %{:crypto => :ADA_BTC, :binance => "ADABTC", :bitfinex => "ADABTC"} # ADABTC
    ]

    def get_crypto_list() do
        @crypto_list
    end


    def get_cryptos(exchange) do
        create_crypto_list(exchange, @crypto_list, [])
    end

    defp create_crypto_list(exchange, list, return_list) do 
        if List.first(list) != nil do
            [head | tail] = list
            return_list = [head[exchange] | return_list]
            create_crypto_list(exchange, tail, return_list)
        else
            return_list
        end
    end

    def get_crypto_name(exchange, concrete_name_coin) do
        search_crypto_name(exchange, concrete_name_coin, @crypto_list)
    end

    defp search_crypto_name(exchange, concrete_name_coin, crypto_list) do
        [head | tail] = crypto_list
        if head[exchange] == concrete_name_coin do
            head[:crypto]
        else 
            search_crypto_name(exchange, concrete_name_coin, tail)
        end
    end
end
