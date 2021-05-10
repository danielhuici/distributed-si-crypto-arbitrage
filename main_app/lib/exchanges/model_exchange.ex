defmodule Exchange.Model do
    @exchange_list  %{
        :binance => Exchange.Binance,
        :bitfinex => Exchange.Bitfinex,
        :kraken => Exchange.Kraken
    }
    
    def get_module_handler(exchange) do
        @exchange_list[exchange]
    end

    def get_exchange_list() do
        Map.keys(@exchange_list)
    end
end
