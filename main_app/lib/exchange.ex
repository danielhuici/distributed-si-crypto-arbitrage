defmodule Exchange do
    @callback operate(list_coin :: map) :: nil
end 