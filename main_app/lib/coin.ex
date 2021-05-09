defmodule Coin do
    def get_concrete_name(coin) do
        elem(coin, 1)
    end

    def get_global_name(coin) do
        elem(coin, 0)
    end

    def create_coin(global_name, concrete_name) do
        {global_name, concrete_name}
    end
end
