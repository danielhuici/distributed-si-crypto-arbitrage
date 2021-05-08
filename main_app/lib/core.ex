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





