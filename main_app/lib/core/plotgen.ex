defmodule Core.Plotgen do
	@behaviour DistributedModule
    def init() do
        IO.puts("[PLOTGEN] Started")
		#pruebas_graficos()
		value_handler_pid = spawn(fn -> value_handler(%{}) end)
        spawn(fn -> ask_arbitrage_values(NodeRepository.get_module_pid("calculator"), value_handler_pid) end)
		plotmaker(value_handler_pid)
    end

    defp ask_arbitrage_values(calculator_pid, value_handler_pid) do
        Process.sleep(20000)
        send(calculator_pid, {:get_values, self()})
        receive do
            {:arbitrage_values, arbitrage_map} ->
				iterate_coins(arbitrage_map[:basic], value_handler_pid)
                ask_arbitrage_values(calculator_pid, value_handler_pid)
        end
    end

	defp value_handler(result_map) do
		receive do
			{:new_value, coin, exchange, profit} ->
				value_handler(insert_value(coin, exchange, profit, result_map))
			{:result_map, pid} -> 
				send(pid, {result_map})
				value_handler(result_map)
			{:end} ->
				#IO.puts("END: #{inspect(result_map)}")
				value_handler(result_map)
		end
	end

	defp plotmaker(value_handler_pid) do
		IO.puts("OK!")
		receive do
			{:create_plot, coin, date_init, date_end, webserver_pid} ->
				IO.puts("Vamos a hacer un plot!")
				send(value_handler_pid, {:result_map, self()})
				receive do
					{result_map} -> 
						IO.puts("Generamos el plot!")
						generate_plot_coin(coin, date_init, date_end, result_map[coin])
						send(webserver_pid, {:ok})
						plotmaker(value_handler_pid)
						
				end
			_ -> IO.puts("what?")
					plotmaker(value_handler_pid)
		end
	end

    # Generate one plot for every coin
    defp iterate_coins(arbitrage_map, value_handler_pid) do
		#IO.puts("Lo que recibo AL PRINCIPIO: #{inspect(Jason.encode!(result_map))}")
		result_map = Enum.map(arbitrage_map, fn {coin, exchanges} ->
			Enum.map(exchanges, fn {exchange, value} ->
				send(value_handler_pid, {:new_value, coin, exchange, value[:profit]})
			end)
		end)
		send(value_handler_pid, {:end})
    end

	defp insert_value(coin, exchange, profit, result_map) do
		result_map = if result_map[coin] == nil do
			Map.put(result_map, coin, %{})
		else result_map end

		result_map = if result_map[coin][exchange] == nil do
			map = Map.put(result_map[coin], exchange, [])
			Map.put(result_map, coin, map)
		else result_map
		end
		#IO.puts("En este punto, #{inspect(profit)}")
		list_profits = result_map[coin][exchange]
		#list_profits = if length(list_profits) > 7 do
		#	[_ | list] = list_profits
		#		list
		#else list_profits
		#end
		new_list_profits = list_profits ++ [{DateTime.utc_now, profit}]
		#IO.puts("Un poco más abajo. List profits: #{inspect(list_profits)}, New: #{inspect(new_list_profits)} |||\n Más: #{inspect(result_map)}")

		map = Map.put(result_map[coin], exchange, new_list_profits)
		Map.put(result_map, coin, map)
	end

	defp generate_plots(coins, date_init, date_end) do
		if List.first(coins) != nil do
			[{coin, exchanges} | tail] = coins
			try do
				Gnuplot.plot(create_params(Atom.to_string(coin), Map.to_list(exchanges)), create_datasets(Map.to_list(exchanges), [], date_init, date_end))
			rescue
				_ -> IO.puts("Continue...")
			end			
			generate_plots(tail, date_init, date_end)
		end
	end

	defp generate_plot_coin(coin, date_init, date_end, exchanges) do
		#try do
			datasets = create_datasets(Map.to_list(exchanges), [], date_init, date_end)
			IO.puts("DATASETS: #{inspect(datasets)}")
			Gnuplot.plot(create_params(Atom.to_string(coin), Map.to_list(exchanges)), datasets)
		#rescue
		#	_ -> IO.puts("Continue...")	
		#end
	end

	defp create_datasets(exchanges, datasets, date_init, date_end) do
		#points = [-30, -25, -20, -15, -10, -5, 0]
		
		if List.first(exchanges) != nil do
			[{exchange, profits} | tail] = exchanges
			new_profits = iterate_profits(profits, 0, date_init, date_end, [])
			datasets = datasets ++ [new_profits]
			create_datasets(tail,  datasets, date_init, date_end)
		else datasets end
	end

	defp iterate_profits(profits, x_axis, date_init, date_end, result) do
		if List.first(profits) != nil do
			[{datetime, profit} | tail] = profits
			IO.puts("Hola????: #{inspect(datetime)} --- #{inspect(date_init)} ----- #{inspect(date_end)} ")
			IO.puts("First compare: #{inspect(DateTime.compare(date_init, datetime))}")
			IO.puts("Second compare: #{inspect(DateTime.compare(date_end, datetime))}")
			result = if (DateTime.compare(date_init, datetime) == :lt and DateTime.compare(date_end, datetime) == :gt) do
				IO.puts("Insaid!")
				result = result ++ [{x_axis, profit}]
			else result end
			
			iterate_profits(tail, x_axis + 5, date_init, date_end, result)
		else
			result
		end
	end

	defp create_params(title, exchanges) do
		params = [
			[:set, :title, title],
			[:set, :xlabel, "Time (min)"],
			[:set, :ylabel, "Profit"],
			[:set, :term, :png, :size, '1920,1080'],
			[:set, :output, "#{title}.png"],
			~w(set key left top)a,
			~w(set grid xtics ytics)a,
		]
		
		IO.puts("Check create plot: #{inspect(create_plots(exchanges, 1, []))}")
		params ++ [Gnuplot.plots(create_plots(exchanges, 1, []))]
	end

	defp create_plots(exchanges, i, plots) do
		if List.first(exchanges) != nil do
			[{exchange, profit} | tail] = exchanges
			plots = plots ++ [["-", :title, Atom.to_string(exchange), :with, :lines, :ls, i]]
			create_plots(tail, i + 1, plots)
		else 
			plots
		end
	end

	defp date_to_string() do
		date = Date.to_string(Date.utc_today)
		time = String.split(Time.to_string(Time.utc_now), ".")

		date <> time
	end

    def pruebas_graficos() do
		points      = [1,2,3,4,5,6,7,8]
		clojure_gui = [1.487, 1.397, 1.400, 1.381, 1.440, 5.784, 49.275]
		elixir_gui  = [0.005, 0.010, 0.004, 0.059, 0.939, 5.801, 43.464]
		elixir_png  = [0.002, 0.010, 0.049, 0.040, 0.349, 4.091, 41.521]
		ubuntu_t2m  = [0.004, 0.002, 0.001, 0.008, 0.211, 1.873, 19.916]
		ubuntu_strm = [0.002, 0.001, 0.001, 0.009, 0.204, 1.279, 12.858]
		datasets = for ds <- [clojure_gui, elixir_gui, elixir_png, ubuntu_t2m, ubuntu_strm], do:
		Enum.zip(points, ds)

		Gnuplot.plot("'test.data'")
	end

end