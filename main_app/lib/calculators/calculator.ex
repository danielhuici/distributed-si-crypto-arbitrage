# Interface Calculator

defmodule Calculator do
    @callback calculate(coin_values_map :: map) :: map
end 