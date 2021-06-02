import Gnuplot

defmodule Core.Initializer do
	def init_all() do
		IO.puts("")
		IO.puts(" _______                             ")
		IO.puts("(_______)                   _        ")
		IO.puts(" _        ____ _   _ ____ _| |_ ___  ")
		IO.puts("| |      / ___) | | |  _ (_   _) _ \ ")
		IO.puts("| |_____| |   | |_| | |_| || || |_| |")
		IO.puts(" \______)_|    \__  |  __/  \__)___/ ")
		IO.puts("              (____/|_|              ")
		IO.puts(" _______       _     _                                     ")
		IO.puts("(_______)     | |   (_)  _                                 ")
		IO.puts(" _______  ____| |__  _ _| |_  ____ _____  ____ _____  ____ ")
		IO.puts("|  ___  |/ ___)  _ \| (_   _)/ ___|____ |/ _  | ___ |/ ___)")
		IO.puts("| |   | | |   | |_) ) | | |_| |   / ___ ( (_| | ____| |    ")
		IO.puts("|_|   |_|_|   |____/|_|  \__)_|   \_____|\___ |_____)_|    ")
		IO.puts("                                        (_____|            ")
		IO.puts("")
		IO.puts("Current O.S: #{inspect(:os.type)}")
		init_modules(NodeRepository.get_modules(), elem(:os.type, 0))
		init_workers(NodeRepository.get_workers(), elem(:os.type, 0))
		
		

		Process.sleep(120000)
	end

	

	defp init_modules(rows, os) do
		if List.first(rows) != nil do
			[module | tail] = rows

			name = List.first(module)
			address = List.last(module)

			case os do
				:win32 -> init_modules_win32(name, address)
				:unix -> init_modules_unix(name, address)
			end
		
			init_modules(tail, os)
		end
	end

	defp init_modules_win32(name, address) do
		case name do
			"pool" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.WorkerPool)"]) end)
			"proxy" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Proxy)"]) end)
			"calculator" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Calculator)"]) end)
			"master" -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Master)"]) end)
			"plotgen" ->  spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Plotgen)"]) end)
		end
	end

	defp init_modules_unix(name, address) do
		case name do
			"pool" -> spawn(fn -> System.cmd("mix", ["run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.WorkerPool)"]) end)
			"proxy" -> spawn(fn -> System.cmd("mix", ["run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Proxy)"]) end)
			"calculator" -> spawn(fn -> System.cmd("mix", ["run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Calculator)"]) end)
			"master" -> spawn(fn -> System.cmd("mix", ["run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Master)"]) end)
			"plotgen" ->  spawn(fn -> System.cmd("mix", [ "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Plotgen)"]) end)
		end
	end

	defp init_workers(rows, os) do
		if List.first(rows) != nil do
			[worker | tail] = rows

			name = List.first(worker)
			address = List.last(worker)

			case os do
				:win32 -> spawn(fn -> System.cmd("cmd.exe", ["/c", "start", "mix", "run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Worker)"]) end)
				:unix -> spawn(fn -> System.cmd("mix", ["run", "-e", "Core.Initializer.register_and_launch(:#{String.to_atom(name)}, :'#{String.to_atom(address)}', Core.Worker)"]) end)
			end

			init_workers(tail, os)
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





