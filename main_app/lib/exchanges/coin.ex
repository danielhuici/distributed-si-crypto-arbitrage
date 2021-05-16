defmodule Coin do
    def get_concrete_name(coin) do
        elem(coin, 1)
    end

    def get_global_name(coin) do
        elem(coin, 0)
    end

    def get_first_coin(coin) do
        List.first(String.split(Atom.to_string(coin), "_"))
    end

    def get_second_coin(coin) do
        List.last(String.split(Atom.to_string(coin), "_"))
    end

    def create_coin(global_name, concrete_name) do
        {global_name, concrete_name}
    end
end
