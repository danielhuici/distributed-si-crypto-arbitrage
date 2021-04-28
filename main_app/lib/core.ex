# FICHERO: fallos.ex
# TIEMPO: +32h
# DESCRIPCION: Implementación de una arquitectura master-worker con tolerancia a fallos
require Logger

defmodule Core.Initializer do
	
	def init() do
		init_workers(Nodes.get_worker_list())
		init_modules(Nodes.get_module_list())
		receive do
			_ -> IO.puts("Nunca debería llegar aquí")
		end
	end


	def init_modules(module_list) do
		IO.puts("Init modules")
		[module | tail] = module_list
		spawn(fn -> register_and_launch(module.name, module.address, module.function) end)
		#Process.sleep(500)
		if List.first(tail) != nil do
			init_modules(tail)
		else 
			IO.puts("Hasta el infinito...")
			Process.sleep(99000)
		end
	end

	def init_workers(worker_list) do
		[worker | tail] = worker_list
		spawn(fn -> register_and_launch(worker.name, worker.address, &Core.Worker.init/0) end)
		if List.first(tail) != nil do
			init_workers(tail)
		end
	end

	def veamosxd() do
		spawn(fn -> Core.Initializer.register_and_launch(:pool, "pool@127.0.0.1", &Core.WorkerPool.init/0) end)
		spawn(fn -> Core.Initializer.register_and_launch(:proxy, "proxy@127.0.0.1", &Core.Proxy.init/0) end)
		spawn(fn -> Core.Initializer.register_and_launch(:calculator, "calculator@127.0.0.1", &Core.Calculator.init/0) end)
		spawn(fn -> Core.Initializer.register_and_launch(:worker, "worker@127.0.0.1", &Core.Worker.init/0) end)
		spawn(fn -> Core.Initializer.register_and_launch(:master, "master@127.0.0.1", &Core.Master.init/0) end)
		
		Process.sleep(99000)
	end


	def register_and_launch(node_name, node_addr, function) do
		IO.puts("Starting #{inspect(node_name)} with address #{inspect(node_addr)} and function #{inspect(function)} and cookie #{inspect(Nodes.get_cookie())}")
		Node.start String.to_atom(node_addr)
		Node.set_cookie String.to_atom("testing")
		Process.register(self(), node_name)
		#Nodes.set_pid(node_name, self())
		function.()
	end

end


defmodule Core.Worker do
		def init() do
			IO.puts("[WORKER] #{inspect(self())} started")
			receive do
				{:req, {proxy_pid, exchange}} -> spawn(fn -> exchange_factory(exchange) end)
												 handle_monitor(proxy_pid)
			end			
		end

		def handle_monitor(proxy_pid) do
			send(proxy_pid, {:alive})
			Process.sleep(3000)
			handle_monitor(proxy_pid)
		end

		def exchange_factory(exchange) do
			IO.puts("[WORKER] Factory creates insance for monitor #{inspect(exchange)}")
			function = Exchange.get_handler_function(exchange)
			function.([])
		end

end

defmodule Core.WorkerPool do

	def add_worker(worker, lista) do
	IO.inspect lista, label: "POOL DE WORKERS: List add:"
		lista ++ [worker]
	end
	
	def init() do
		IO.puts("POOL: iniciado")
		listen(Nodes.get_worker_list())
	end

	def pop_worker(list) do
		IO.puts("[POOL] List status #{inspect(list)}")
		tuple = List.pop_at(list, 0) # {%{worker}, [remaining_workers]}
		worker = elem(tuple, 0)
		if worker != nil do
			IO.puts("[POOL] Pop worker from list #{inspect(worker)}")
			send(Nodes.get_pid(:master), {:receive_worker, Nodes.get_pid(worker.name)})
			elem(tuple, 1)
		else 
			send(Nodes.get_pid(:master), {:no_workers})
			[]
		end

	end
		
	def listen(list) do
		receive do
			{:aniadir, worker} -> listen(add_worker(worker, list))
			{:request_worker} -> listen(pop_worker(list))			  
			_-> IO.puts("Error")
		end
	end
end

defmodule Core.Master do
	def init() do
		IO.puts("[MASTER] Esperando al resto de módulos...")
		Process.sleep(3000)
		IO.puts("[MASTER] Iniciado. Comienza interacción")
		master(Exchange.get_exchange_list())
	end

	def master(exchange_list) do
		if exchange_list != [] do
			[exchange | tail] = exchange_list
			if exchange != nil do
				send(Nodes.get_pid(:pool), {:request_worker})
			end
			receive do
				{:receive_worker, worker} -> IO.puts("[MASTER] Got worker #{inspect(worker)} -> will monitor #{inspect(exchange_list)} ")													
											send(Nodes.get_pid(:proxy), {exchange, worker})
											IO.puts("[MASTER] Remaining exchanges: #{inspect(tail)}")
											master(tail)
				{:no_workers} -> IO.puts("There is not enough workers. Wait and try again...")
									Process.sleep(10000)
											
				{resultado} -> IO.puts("MASTER: Worker ha terminado. Lo envio a POOL DE WORKERS. naah ahora es nuevo: #{inspect(resultado)}")
								#send({:pool,pool_pid},{:aniadir, worker_pid})
			end
		end
		master(exchange_list)
	end
	
end

defmodule Core.Proxy do
	def init() do
		IO.puts("[PROXY] iniciado")
		proxy()
	end

	defp proxy() do
		receive do
			{exchange, worker} -> IO.puts("[PROXY] Master quiere que monitorice worker. Abro hilo para #{inspect(worker)}")
												spawn(fn -> Core.Proxy.start_monitor(worker, exchange) end)
												proxy()
		end
	end

	def start_monitor(worker, exchange) do
		IO.puts("[PROXY] Monitor for worker #{inspect(worker)} starts")
		Node.monitor(elem(worker, 1), true)
		send(worker, {:req, {self(), exchange}})
		monitor(worker, exchange)
	end

	defp monitor(worker, exchange) do
		receive do
			{:alive} -> IO.puts("[PROXY] Worker is alive. Keep goin'")
						monitor(worker, exchange)
			
			after 30_000 -> IO.puts("[PROXY] Worker is down.")
						#if (n == 4) do
						#	IO.puts("PROXY_HILO_#{inspect(n)}: HASTA LOS HUEVOS DE ESPERAR A ESTE WORKER")
						#	IO.puts("PROXY_HILO_#{inspect(n)}: Ha muerto WORKER: #{inspect(worker)}")
						#	IO.puts("PROXY_HILO_#{inspect(n)}: Repito peticion CLIENTE")
						#	send(Nodes.get_pid(:master), {:node_down, })
						#else
						#spawn( fn -> Proxy.hilo(worker, numero, n) end)
						monitor(worker, exchange)
						
		end
	end
end

defmodule Core.Calculator do
	def init() do 
		set_strategy(Calculator.get_current_function())
	end

	defp set_strategy(strategy) do
		init_coin_map = create_map(ModelCrypto.get_crypto_list(), %{})
		handle_values(init_coin_map, %{}, strategy)


	end

	def create_map(cryptos, map) do 
		map = if List.first(cryptos) != nil do
			[coin | tail] = cryptos
			map = Map.put(map, coin.crypto, %{})
			create_map(tail, map)
		else 
			map
		end
		map
	end

	def handle_values(coin_value_map, arbitrage_map, strategy) do
		receive do
			{:new_value, {exchange, coin, value}} -> IO.puts("[CALCULATOR] New value from #{inspect(exchange)} - #{inspect(coin)} with value: #{inspect(value)}")
													map = Map.put(coin_value_map[ModelCrypto.get_crypto_name(exchange, coin)], exchange, value)
													coin_value_map = Map.put(coin_value_map, ModelCrypto.get_crypto_name(exchange, coin), map)
													strategy.(coin_value_map)
													handle_values(coin_value_map, arbitrage_map, strategy)
			{:new_calc, {coin, new_arbitrage_calc}} ->  IO.puts("[CALCULATOR] Got new data calculated for coin #{inspect(coin)}: #{inspect(new_arbitrage_calc)}")
														handle_values(coin_value_map, Map.put(arbitrage_map, coin, new_arbitrage_calc), strategy)
			{:get_values, api_pid} -> IO.puts("[CALCULATOR] Send data to Web server")
									  send(api_pid, {:arbitrage_values, arbitrage_map})
									  handle_values(coin_value_map, arbitrage_map, strategy)
			
			_-> IO.puts("CALCULATOR: Error. Valor de recepción no controlado")

		end
	end


	#%{BTC_USD:
	#		%{
	#		min_exchange: Binance
	#		max_exchange: Bitfinex
	#		min_value: 
	#		max_value: 
	#	}

end