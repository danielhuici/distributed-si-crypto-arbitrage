defmodule Calculator.Model do
    @list_calcs [
        Calculator.BasicStrategy,
        Calculator.TriangularStrategy
    ]
    
    def get_strategy_lists() do
        @list_calcs
    end
end