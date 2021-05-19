defmodule Core.Plotgen do
	@behaviour DistributedModule
    def init() do
        IO.puts("[PLOTGEN] Started")
		graphic_pid = spawn(fn -> value_handler(%{}) end)
        operate(NodeRepository.get_module_pid("calculator"), graphic_pid)
    end

    defp operate(calculator_pid, graphic_pid) do
        Process.sleep(150000)
        send(calculator_pid, {:get_values, self()})
        receive do
            {:arbitrage_values, arbitrage_map} ->
				iterate_coins(arbitrage_map[:basic], graphic_pid)
                operate(calculator_pid, graphic_pid)
        end
    end

	defp value_handler(result_map) do
		receive do
			{:new_value, coin, exchange, profit} ->
				value_handler(insert_value(coin, exchange, profit, result_map))
			{:end} ->
				IO.puts("END: #{inspect(result_map)}")
				generate_plots(result_map)
				value_handler(result_map)
		end
		
	end

    # Generate one plot for every coin
    defp iterate_coins(arbitrage_map, graphic_pid) do
		#IO.puts("Lo que recibo AL PRINCIPIO: #{inspect(Jason.encode!(result_map))}")
		result_map = Enum.map(arbitrage_map, fn {coin, exchanges} ->
			Enum.map(exchanges, fn {exchange, value} ->
				send(graphic_pid, {:new_value, coin, exchange, value[:profit]})
			end)
		end)
		send(graphic_pid, {:end})
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
		#IO.puts("En este punto, #{inspect(result_map)}")
		list_profits = result_map[coin][exchange]
		list_profits = if length(list_profits) > 7 do
			[_ | list] = list_profits
			list
		else list_profits
		end
		new_list_profits = list_profits ++ [profit]
		#IO.puts("Un poco más abajo. List profits: #{inspect(list_profits)}, New: #{inspect(new_list_profits)} |||\n Más: #{inspect(result_map)}")

		map = Map.put(result_map[coin], exchange, new_list_profits)
		Map.put(result_map, coin, map)
	end

	defp generate_plots(coins) do
		if List.first(coins != nil) do
			[{coin, exchanges} | tail] = coins
			Gnuplot.plot(create_params(Atom.to_string(coin), Map.to_list(exchanges)), create_datasets(Map.to_list(exchanges), []))
			generate_plots(tail)
		end
	end

	defp create_datasets(exchanges, datasets) do
		points = [-30, -25, -20, -15, -10, -5, 0]
		if List.first(exchanges) != nil do
			[{exchange, profits} | tail] = exchanges
			datasets = datasets ++ [Enum.zip(points, profits)]
			create_datasets(tail, datasets)
		else 
			datasets
		end
	end


	defp create_params(title, exchanges) do
		params = [
			[:set, :title, title],
			[:set, :xlabel, "Time (min)"],
			[:set, :ylabel, "Profit"],
			[:set, :term, :png, :size, '512,512'],
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

	def final_graphic(coin, exchanges) do
		Gnuplot.plot(create_params(coin, exchanges), create_datasets(exchanges, []))
		IO.puts("OK")
	end

    def pruebas_graficos() do
		IO.puts("Haga algo mamaguevo")
		points      = [-30, -25, 20]
		clojure_gui = [1, 2, 1]
		elixir_gui  = [4,1, 2]
		elixir_png  = [1, 1, 1]
		ubuntu_t2m  = [2, 1, 2]
		ubuntu_strm = [1, 1, 1]
		datasets = for ds <- [clojure_gui, elixir_gui, elixir_png, ubuntu_t2m, ubuntu_strm], do:
		Enum.zip(points, ds)

		Gnuplot.plot([
		[:set, :title, "Time to render scatter plots"],
		[:set, :xlabel, "Profit"],
		[:set, :ylabel, "Time (min)"],
		[:set, :term, :png, :size, '512,512'],
		[:set, :output, "rand.png"],
		~w(set key left top)a,
		~w(set grid xtics ytics)a,
		~w(set style line 1 lw 2 lc '#63b132')a,
		~w(set style line 2 lw 2 lc '#2C001E')a,
		~w(set style line 3 lw 2 lc '#5E2750')a,
		~w(set style line 4 lw 2 lc '#E95420')a,
		~w(set style line 5 lw 4 lc '#77216F')a,
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




