defmodule Calculator do
    @current :basic_strategy
    @list_calcs [
        %{:basic_strategy => &Calculator.BasicStrategy.calculate/1}
    ]

    def get_current_calc do @current end
    
    #TODO: Cambiar!!
    def get_current_function() do
        &Calculator.BasicStrategy.calculate/1
    end
end