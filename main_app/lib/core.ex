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
		IO.puts("Lanzamos: Core.Initializer.register_and_launch(#{inspect(module.name)}, #{inspect(module.address)}, #{inspect(module.function)})")
		spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(#{inspect(module.name)}, '#{module.address}', #{inspect(module.function)})"]) end)
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
		spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:pool, 'pool@127.0.0.1', &Core.WorkerPool.init/0)"]) end)
		IO.puts("Ok done")
		System.cmd("cmd.exe", ["/c", "start"])
		System.cmd("cmd.exe", ["/c", "start"])
		#Core.Initializer.register_and_launch(:pool, "pool@127.0.0.1", &Core.WorkerPool.init/0)
		#Core.Initializer.register_and_launch(:proxy, "proxy@127.0.0.1", &Core.Proxy.init/0
		#Core.Initializer.register_and_launch(:calculator, "calculator@127.0.0.1", &Core.Calculator.init/0
		#Core.Initializer.register_and_launch(:worker, "worker@127.0.0.1", &Core.Worker.init/0
		#Core.Initializer.register_and_launch(:master, "master@127.0.0.1", &Core.Master.init/0
	end

	def register_and_launch(node_name, node_addr, module) do
		IO.puts("Starting #{inspect(node_name)} with address #{inspect(node_addr)} and module #{inspect(module)} and cookie #{inspect(Nodes.get_cookie())}")
		Node.start(String.to_atom(node_addr))
		Node.set_cookie(String.to_atom("testing"))
		Process.register(self(), node_name)
		#Nodes.set_pid(node_name, self())
		module.init()
	end

end


defmodule Core.Worker do
	@behaviour DistributedModule
	def init() do
		IO.puts("[WORKER] #{inspect(self())} started")
		receive do
			{:req, {proxy_pid, exchange}} -> exchange_factory(exchange)
												handle_monitor(proxy_pid)
		end			
	end

	defp handle_monitor(proxy_pid) do
		send(proxy_pid, {:alive})
		Process.sleep(3000)
		handle_monitor(proxy_pid)
	end

	defp exchange_factory(exchange) do
		IO.puts("[WORKER] Factory creates insance for monitor #{inspect(exchange)}")
		exchange_module = Exchange.Model.get_module_handler(exchange)
		spawn(fn -> exchange_module.operate([]) end)
	end

end

defmodule Core.WorkerPool do
	@behaviour DistributedModule
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
	@behaviour DistributedModule
	def init() do
		IO.puts("[MASTER] Wait till rest of modules gets ready...")
		Process.sleep(1000)
		IO.puts("[MASTER] Started")
		master(Exchange.Model.get_exchange_list())
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
				after 6_000 -> IO.puts("No recibo nada...")
			end
		end
		master(exchange_list)
	end
	
end

defmodule Core.Proxy do
	@behaviour DistributedModule
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
	@behaviour DistributedModule
	def init() do 
		init_coin_map = create_map(ModelCrypto.get_crypto_list(), %{})
		handle_values(init_coin_map, %{})
	end


	defp create_map(cryptos, map) do 
		map = if List.first(cryptos) != nil do
			[coin | tail] = cryptos
			map = Map.put(map, coin.crypto, %{})
			create_map(tail, map)
		else 
			map
		end
		map
	end

	defp handle_values(coin_value_map, arbitrage_map) do
		receive do 
			{:new_value, {exchange, coin, value}} -> IO.puts("[CALCULATOR] New value from #{inspect(exchange)} - #{inspect(coin)} with value: #{inspect(value)}")
													map = Map.put(coin_value_map[ModelCrypto.get_crypto_name(exchange, coin)], exchange, value)
													coin_value_map = Map.put(coin_value_map, ModelCrypto.get_crypto_name(exchange, coin), map)
													call_strategy(Calculator.Model.get_strategy_lists(), coin_value_map)
													handle_values(coin_value_map, arbitrage_map)
			{:new_calc, {coin, new_arbitrage_calc}} ->  IO.puts("[CALCULATOR] Got new data calculated for coin #{inspect(coin)}: #{inspect(new_arbitrage_calc)}")
														handle_values(coin_value_map, Map.put(arbitrage_map, coin, new_arbitrage_calc))
			{:get_values, api_pid} -> IO.puts("[CALCULATOR] Send data to Web server")
									  send(api_pid, {:arbitrage_values, arbitrage_map})
									  handle_values(coin_value_map, arbitrage_map)
			
			_-> IO.puts("CALCULATOR: Error. Valor de recepción no controlado")

		end
	end

	def call_strategy(list_strategies, coin_value_map) do
		if list_strategies != [] do
			[strategy | tail] = list_strategies
			strategy.calculate(coin_value_map)
			call_strategy(tail, coin_value_map)
		end
	end
end