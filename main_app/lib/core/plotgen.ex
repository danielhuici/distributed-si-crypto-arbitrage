defmodule Core.Plotgen do
	@behaviour DistributedModule
    def init() do
        DebugLogger.print("[PLOTGEN] Started")
		#pruebas_graficos()

		value_handler_pid = spawn(fn -> value_handler(%{}) end)
        spawn(fn -> ask_arbitrage_values(NodeRepository.get_module_pid("calculator"), value_handler_pid) end)
		plotmaker(value_handler_pid)
    end

    defp ask_arbitrage_values(calculator_pid, value_handler_pid) do
        Process.sleep(300000)
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
				#DebugLogger.print("END: #{inspect(result_map)}")
				value_handler(result_map)
		end
	end

	defp plotmaker(value_handler_pid) do
		DebugLogger.print("OK!")
		receive do
			{:create_plot, coin, date_init, date_end, webserver_pid} ->
				DebugLogger.print("Vamos a hacer un plot!")
				send(value_handler_pid, {:result_map, self()})
				receive do
					{result_map} -> 
						DebugLogger.print("Generamos el plot!")
						generate_plot_coin(coin, date_init, date_end, result_map[coin])
						send(webserver_pid, {:ok})
						plotmaker(value_handler_pid)
						
				end
			_ -> DebugLogger.print("No debug")
					plotmaker(value_handler_pid)
		end
	end

    # Generate one plot for every coin
    defp iterate_coins(arbitrage_map, value_handler_pid) do
		#DebugLogger.print("Lo que recibo AL PRINCIPIO: #{inspect(Jason.encode!(result_map))}")
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
		#DebugLogger.print("En este punto, #{inspect(profit)}")
		list_profits = result_map[coin][exchange]
		#list_profits = if length(list_profits) > 7 do
		#	[_ | list] = list_profits
		#		list
		#else list_profits
		#end
		new_list_profits = list_profits ++ [{DateTime.utc_now, profit}]
		#DebugLogger.print("Un poco más abajo. List profits: #{inspect(list_profits)}, New: #{inspect(new_list_profits)} |||\n Más: #{inspect(result_map)}")

		map = Map.put(result_map[coin], exchange, new_list_profits)
		Map.put(result_map, coin, map)
	end

	defp generate_plots(coins, date_init, date_end) do
		if List.first(coins) != nil do
			[{coin, exchanges} | tail] = coins
			try do
				Gnuplot.plot(create_params(Atom.to_string(coin), Map.to_list(exchanges)), create_datasets(Map.to_list(exchanges), [], date_init, date_end))
			rescue
				_ -> DebugLogger.print("Continue...")
			end			
			generate_plots(tail, date_init, date_end)
		end
	end

	defp generate_plot_coin(coin, date_init, date_end, exchanges) do
		try do
			datasets = create_datasets(Map.to_list(exchanges), [], date_init, date_end)
			#DebugLogger.print("DATASETS: #{inspect(datasets)}")
			Gnuplot.plot(create_params(Atom.to_string(coin), Map.to_list(exchanges)), datasets)

			#Gnuplot.plot(create_params(Atom.to_string(coin), Map.to_list(exchanges)), [[{"21-06-07--19:00", 1.0000119325634749}, {"21-06-07--19:05", 1.0001524304559903}, {"21-06-07--19:10", 1.0002026298167541}, {"21-06-07--19:15", 1.0007524258268388}, {"21-06-07--19:20", 1.0008721283196567}], [{"21-06-07--19:00", 1.0008676842327315}, {"21-06-07--19:05", 1.0010332693713655}, {"21-06-07--19:10", 1.0012191914109267}, {"21-06-07--19:15", 1.0005017525298208}, {"21-06-07--19:20", 1.000443914565402}], [{"21-06-07--19:00", 1.0008796271499034}, {"21-06-07--19:05", 1.000880704669161}, {"21-06-07--19:10", 1.0010163556502136}, {"21-06-07--19:15", 1.0012545558882215}, {"21-06-07--19:20", 1.0013164300355228}]])
		rescue
		_ -> DebugLogger.print("Continue...")	
		end
	end

	defp create_datasets(exchanges, datasets, date_init, date_end) do
		#points = [-30, -25, -20, -15, -10, -5, 0]
		
		if List.first(exchanges) != nil do
			[{exchange, profits} | tail] = exchanges
			new_profits = iterate_profits(profits, date_init, date_end, [])
			datasets = datasets ++ [new_profits]
			create_datasets(tail,  datasets, date_init, date_end)
		else datasets end
	end

	defp iterate_profits(profits, date_init, date_end, result) do
		if List.first(profits) != nil do
			[{datetime, profit} | tail] = profits
			DebugLogger.print("Hola????: #{inspect(datetime)} --- #{inspect(date_init)} ----- #{inspect(date_end)} ")
			#DebugLogger.print("First compare: #{inspect(DateTime.compare(date_init, datetime))}")
			#DebugLogger.print("Second compare: #{inspect(DateTime.compare(date_end, datetime))}")
			result = if (DateTime.compare(date_init, datetime) == :lt and DateTime.compare(date_end, datetime) == :gt) do
				DebugLogger.print("Datetime: #{inspect(DateTime.to_string(datetime))}. Format: #{inspect(format_datetime(DateTime.to_string(datetime)))}")
				result = result ++ [{format_datetime(DateTime.to_string(datetime)), profit}]
			else result end
			
			iterate_profits(tail, date_init, date_end, result)
		else
			result
		end
	end

	defp format_datetime(datetime) do
		[date | time] = String.split(datetime, " ")
		time = String.slice(List.first(time), 0, 5)
		date = String.slice(date, 2, 10)
		date <> "--" <> time
	end

	defp create_params(title, exchanges) do
		params = [
			[:set, :title, String.replace(title, "_", "-")],
			[:set, :xlabel, "Time (min)"],
			[:set, :ylabel, "Profit"],
			[:set, :term, :png, :size, '1920,1080'],
			[:set, :output, "#{title}.png"],
			[:set, :xdata, :time],
			[:set, :timefmt, "%y-%m-%d--%H:%M"],
			[:set, :format, :x, "%m/%d %H:%M"],
			#[:plot, "-", :using, '1:2'],
			~w(set key left top)a,
			~w(set grid xtics ytics)a,
		]
		
		DebugLogger.print("Check create plot: #{inspect(create_plots(exchanges, 1, []))}")
		params ++ [Gnuplot.plots(create_plots(exchanges, 1, []))]
	end

	defp create_plots(exchanges, i, plots) do
		if List.first(exchanges) != nil do
			[{exchange, profit} | tail] = exchanges
			plots = plots ++ [["-", :using, '1:2', :title, String.replace(Atom.to_string(exchange), "_", "-"), :with, :lines, :ls, i]]
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

		datasets = [[{"95-03-21--20:05",1}, {"95-03-21--20:10",2}]]

		#datasets = []
		Gnuplot.plot([
		[:set, :title, "Time to render scatter plots"],
		[:set, :xlabel, "Points in plot"],
		[:set, :ylabel, "Elapsed (s)"],
		[:set, :xdata, :time],
		[:set, :timefmt, "%y-%m-%d--%H:%M"],
		[:set, :format, :x, "%m/%d %H:%M"],
		
		~w(set xtics rotate by 90)a,
		~w(set key left top)a,
		~w(set grid xtics ytics)a,
		#~w(set xtics add ('Pi' 3.14159))a,
		#~w(set xtics '01/12', 172800, '05/12')a,
		
		~w(set style line 1 lw 2 lc '#63b132')a,
		~w(set style line 2 lw 2 lc '#2C001E')a,
		~w(set style line 3 lw 2 lc '#5E2750')a,
		~w(set style line 4 lw 2 lc '#E95420')a,
		~w(set style line 5 lw 4 lc '#77216F')a,
		[:plot, "-", :using, '1:2'],
		Gnuplot.plots([
			["-", :title, "Clojure GUI", :with, :lines, :ls, 1],
			["-", :title, "Elixir GUI", :with, :lines, :ls, 2],
			["-", :title, "Elixir PNG", :with, :lines, :ls, 3],
			["-", :title, "Elixir t2.m", :with, :lines, :ls, 4],
			["-", :title, "Elixir Stream", :with, :lines, :ls, 5]
		])],
		datasets
		)
	end

end