defmodule Coin.Model do
    @global_coins [
                    :BTC_USD,
                    :ETH_BTC,
                    :LTC_BTC,
                    :ADA_BTC
                  ]
    
    def get_coins() do
        @global_coins
    end

end
