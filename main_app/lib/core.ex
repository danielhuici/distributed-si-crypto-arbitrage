defmodule Core.Initializer do

	def init_all() do
		{:ok, hostname} = :inet.gethostname
		modules = MyXQL.query!(pid, "SELECT name, address FROM modules WHERE id_host IN (SELECT id FROM hosts WHERE hostname='#{hostname}')")
		workers = MyXQL.query!(pid, "SELECT name, address FROM workers WHERE id_host IN (SELECT id FROM hosts WHERE hostname='#{hostname}')")

		init_modules(modules.rows)
		init_workers(workers.rows)

		Process.sleep(60)
	end

	def init_modules(rows) do
		[module | tail] = rows

		name = List.first(module)
		address = List.last(module)

		case name do
			"pool" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.WorkerPool)"]) end)
			"proxy" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Proxy)"]) end)
			"calculator" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Calculator)"]) end)
			"master" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Master)"]) end)
		end

		if List.first(tail) != nil do
			init_modules(tail)
		end
	end

	def init_workers(rows) do
		[worker | tail] = rows

		name = List.first(worker)
		address = List.last(worker)

		spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Worker)"]) end)
		if List.first(tail) != nil do
			init_workers(tail)
		end
	end

	def register_and_launch(node_name, node_addr, module) do
		IO.puts("Starting #{inspect(node_name)} with address #{inspect(node_addr)} and module #{inspect(module)} and cookie #{inspect(Nodes.get_cookie())}")
		Node.start(node_addr)
		Node.set_cookie(String.to_atom("testing"))
		Process.register(self(), node_name)
		#Nodes.set_pid(node_name, self())
		module.init()
	end

end





