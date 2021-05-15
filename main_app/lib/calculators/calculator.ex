# Interface Calculator

defmodule Calculator do
    @callback calculate(coin_values_map :: map, calculator_handler_pid :: string) :: map
end 