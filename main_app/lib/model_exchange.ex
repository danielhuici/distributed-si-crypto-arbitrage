defmodule Exchange do
    @exchange_list  %{
        :binance => &Exchange.Binance.operate/1, 
        :bitfinex => &Exchange.Bitfinex.operate/1
    }
    
    def get_handler_function(exchange) do
        @exchange_list[exchange]
    end

    def get_exchange_list() do
        Map.keys(@exchange_list)
    end
end
