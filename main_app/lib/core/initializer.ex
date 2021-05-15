defmodule Core.Initializer do
	def init_all() do
		init_modules(NodeRepository.get_modules())
		init_workers(NodeRepository.get_workers())

		Process.sleep(120000)
	end

	def init_modules(rows) do
		if List.first(rows) != nil do
			[module | tail] = rows

			name = List.first(module)
			address = List.last(module)

			case name do
				"pool" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.WorkerPool)"]) end)
				"proxy" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Proxy)"]) end)
				"calculator" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Calculator)"]) end)
				"master" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Master)"]) end)
			end
		
			init_modules(tail)
		end
	end

	def init_workers(rows) do
		if List.first(rows) != nil do
			IO.puts("Worker: #{inspect(rows)}")
			[worker | tail] = rows

			name = List.first(worker)
			address = List.last(worker)

			spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Worker)"]) end)
			init_workers(tail)
		end
	end

	def register_and_launch(node_name, node_addr, module) do
		IO.puts("Starting #{inspect(node_name)} with address #{inspect(node_addr)} and module #{inspect(module)} and cookie #{inspect(NodeRepository.get_cookie())}")
		Node.start(node_addr)
		Node.set_cookie(String.to_atom("testing"))
		Process.register(self(), node_name)
		#Nodes.set_pid(node_name, self())
		module.init()
	end

end





