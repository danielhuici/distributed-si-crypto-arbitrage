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
			
			after 30_000 -> IO.puts("[PROXY] Worker is down. Notify Master")
							send(NodeRepository.get_module_pid("master"), {:worker_down, exchange})
		end
	end
end
