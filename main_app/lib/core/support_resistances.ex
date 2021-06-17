defmodule Core.SupportResistances do
	@behaviour DistributedModule
    def init() do
        DebugLogger.print("[SupportResitances] Started")
		#pruebas_graficos()

		value_handler_pid = spawn(fn -> value_handler(%{}) end)
        spawn(fn -> ask_arbitrage_values(NodeRepository.get_module_pid("calculator"), value_handler_pid) end)
        plotmaker(value_handler_pid)
    end

    defp value_handler(result_map) do
       #DebugLogger.print("Value handler ready")
		receive do
			{:new_value, coin, exchange, value} ->
                #DebugLogger.print("New value")
				value_handler(insert_value(coin, exchange, value, result_map))
			{:result_map, pid} -> 
				send(pid, {result_map})
				value_handler(result_map)
			{:end} ->
				#DebugLogger.print("END: #{inspect(result_map)}")
				value_handler(result_map)
		end
	end

     defp ask_arbitrage_values(calculator_pid, value_handler_pid) do
        Process.sleep(300000)
        send(calculator_pid, {:get_market, self()})
        #DebugLogger.print("[SupportResistances] - Go!")
        receive do
            {:market_values, market_map} ->
                #DebugLogger.print("[SupportResistances] - MERCADO: #{inspect(market_map)}")
				iterate_coins(market_map, value_handler_pid)
                ask_arbitrage_values(calculator_pid, value_handler_pid)
        end
    end

     defp iterate_coins(market_map, value_handler_pid) do
        #DebugLogger.print("Market map: #{inspect(market_map)}")
		Enum.map(market_map, fn {coin, exchanges} ->
			Enum.map(exchanges, fn {exchange, data} ->
				send(value_handler_pid, {:new_value, coin, exchange, data})
			end)
		end)
		send(value_handler_pid, {:end})
    end

    defp insert_value(coin, exchange, value, result_map) do
		result_map = if result_map[coin] == nil do
			Map.put(result_map, coin, %{})
		else result_map end

		result_map = if result_map[coin][exchange] == nil do
			map = Map.put(result_map[coin], exchange, [])
			Map.put(result_map, coin, map)
		else result_map
		end
		list_values = result_map[coin][exchange]

		new_list_values = list_values ++ [value]

		map = Map.put(result_map[coin], exchange, new_list_values)
		Map.put(result_map, coin, map)
	end


    defp plotmaker(value_handler_pid) do
		DebugLogger.print("[SupportResistance] Create a plot")
		receive do
			{:create_plot, coin, exchange, date_init, date_end, webserver_pid} ->
				#DebugLogger.print("Vamos a hacer un plot!")
				send(value_handler_pid, {:result_map, self()})
				receive do
					{result_map} -> 
						generate_plot_coin(coin, exchange, date_init, date_end, result_map[coin][exchange])
						send(webserver_pid, {:ok})
						plotmaker(value_handler_pid)
						
				end
			_ -> DebugLogger.print("No debug")
					plotmaker(value_handler_pid)
		end
	end

    defp generate_plot_coin(coin, exchange, date_init, date_end, dataset) do
		try do
            dataset = parse_dataset(dataset, date_init, date_end, [])
            resistances = parse_dataset_nocheck(find_max_peaks(dataset, date_init, date_end, []), [])
            supports = parse_dataset_nocheck(find_min_peaks(dataset, date_init, date_end, []), [])
            dataset = [dataset]
            #DebugLogger.print("[Support] #{inspect(support)}")
            dataset = if List.first(supports) != nil do
            dataset ++ [supports]
            else dataset end
            dataset = if List.first(resistances) != nil do
                dataset ++ [resistances]
            else dataset end
            DebugLogger.print("[DATASETS] #{inspect(dataset)}")
            DebugLogger.print("Go!")
            Gnuplot.plot(create_params(Atom.to_string(coin), exchange, trunc(length(supports) / 2), trunc(length(resistances) / 2)), dataset)
            DebugLogger.print("Done!")
        rescue
		_ -> DebugLogger.print("Continue...")	
		end
	end

    defp parse_dataset(dataset, date_init, date_end, new_list) do
        if List.first(dataset) != nil do
            [{value, datetime} | tail] = dataset
            #DebugLogger.print("Hola????: #{inspect(datetime)} --- #{inspect(date_init)} ----- #{inspect(date_end)} ")
			#DebugLogger.print("First compare: #{inspect(DateTime.compare(date_init, datetime))}")
			#DebugLogger.print("Second compare: #{inspect(DateTime.compare(date_end, datetime))}")
            new_list = if ((DateTime.compare(date_init, datetime) == :lt)
                        and (DateTime.compare(date_end, datetime) == :gt)) do
				#DebugLogger.print("Datetime: #{inspect(DateTime.to_string(datetime))}. Format: #{inspect(format_datetime(DateTime.to_string(datetime)))}")
				new_list = new_list ++ [{format_datetime(DateTime.to_string(datetime)), value}]
			else new_list end
            parse_dataset(tail, date_init, date_end, new_list)
        else new_list end
    end

    defp parse_dataset_nocheck(dataset, new_list) do
        if List.first(dataset) != nil do
            [{value, datetime} | tail] = dataset
            #DebugLogger.print("Datetime: #{inspect(DateTime.to_string(datetime))}. Format: #{inspect(format_datetime(DateTime.to_string(datetime)))}")
			new_list = new_list ++ [{format_datetime(DateTime.to_string(datetime)), value}]
            parse_dataset_nocheck(tail, new_list)
        else new_list end
    end



    defp create_params(title, exchange, n_supports, n_resistances) do
        DebugLogger.print("n_supports: #{inspect(n_supports)} || n_resistances: #{inspect(n_resistances)}")
        support_plots = create_plots("Support", 1, n_supports + 1, [])
        resistances_plots = create_plots("Resistance", n_supports + 1, n_supports + n_resistances + 1, [])
        DebugLogger.print("Support plots: #{inspect(support_plots)} || Resistance plots: #{inspect(resistances_plots)}")
        plots = [["-", :using, '1:2', :title, Atom.to_string(exchange), :with, :lines, :ls, 0]]
        plots = if List.first(support_plots) != nil do
            plots ++ [support_plots]
        else plots end
        plots = if List.first(resistances_plots) != nil do
            plots ++ [resistances_plots]
        else plots end
        #plots = [["-", :using, '1:2', :title, String.replace(Atom.to_string(exchange), "-", "_"), :with, :lines, :ls, 0], support_plots, resistances_plots]
        #plots = [["-", :using, '1:2', :title, String.replace(Atom.to_string(title), "-", "_"), :with, :lines, :ls, 1]]
        DebugLogger.print("Plots: #{inspect(support_plots)} || Resistance plots: #{inspect(resistances_plots)}")
        DebugLogger.print("Final: #{inspect(plots)}")
		params = [
			[:set, :title, String.replace(title, "_", "-")],
			[:set, :xlabel, "Time (min)"],
			[:set, :ylabel, "Value"],
			[:set, :term, :png, :size, '1920,1080'],
			[:set, :output, "#{title}.png"],
			[:set, :xdata, :time],
			[:set, :timefmt, "%y-%m-%d--%H:%M"],
			[:set, :format, :x, "%m/%d %H:%M"],
			~w(set key left top)a,
			~w(set grid xtics ytics)a,
            Gnuplot.plots(plots)
		]
		
		#DebugLogger.print("Check create plot: #{inspect(create_plots(exchanges, 1, []))}")
		#params ++ [Gnuplot.plots(create_plots(exchanges, 1, []))]
	end

    defp create_plots(name, i, j, result) do
        if (i < j) do
            result = result ++ ["-", :using, '1:2', :title, "#{name}" , :with, :lines, :ls, i]
            create_plots(name, i + 1, j, result)
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

    defp find_max_peaks(dataset, date_init, date_end, max_peaks) do
        DebugLogger.print("Dataset status (MAX_PEAKS): #{inspect(dataset)}\n")
        if List.first(dataset) != nil do
            if (length(dataset) > 5) do
                [p1, p2, p3, p4, p5 | tail] = dataset
                max_peaks = if elem(p1, 1) < elem(p2, 1) and elem(p2, 1) < elem(p3, 1) and elem(p4, 1) < elem(p3, 1) and elem(p5, 1) < elem(p4, 1) do
                    DebugLogger.print("Maximo encontrado!!")
                    max_peaks ++ [{elem(p3, 1), date_init}, {elem(p3, 1), date_end}]
                else max_peaks end    
                DebugLogger.print("Lista: #{inspect(max_peaks)}")
                max_peaks
                find_max_peaks(List.delete_at(dataset, 0), date_init, date_end, max_peaks)
            else max_peaks end
        else max_peaks end
    end


    defp find_min_peaks(dataset, date_init, date_end, min_peaks) do
        DebugLogger.print("Dataset status (MIN_PEAKS): #{inspect(dataset)}\n")
        if List.first(dataset) != nil do
            if (length(dataset)  > 5) do
                [p1, p2, p3, p4, p5 | tail] = dataset
                min_peaks = if elem(p1, 1) > elem(p2, 1) and elem(p2, 1) > elem(p3, 1) and elem(p4, 1) > elem(p3, 1) and elem(p5, 1) > elem(p4, 1) do
                    DebugLogger.print("Minimo encontrado!!")
                    min_peaks ++ [{elem(p3, 1), date_init}, {elem(p3, 1), date_end}]
                else min_peaks end    
                DebugLogger.print("Lista: #{inspect(min_peaks)}")
                min_peaks
                find_min_peaks(List.delete_at(dataset, 0), date_init, date_end, min_peaks)
            else min_peaks end
        else min_peaks end
    end

end