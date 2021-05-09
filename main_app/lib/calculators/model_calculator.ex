defmodule Calculator.Model do
    @list_calcs [
        Calculator.BasicStrategy
    ]
    
    def get_strategy_lists() do
        @list_calcs
    end
end