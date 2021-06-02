defmodule Core.Master do
	@behaviour DistributedModule
	def init() do
		DebugLogger.print("[MASTER] Wait till rest of modules are ready...")
		Process.sleep(10000)
		DebugLogger.print("[MASTER] Started")
		master(Exchange.Model.get_exchange_list(), NodeRepository.get_module_pid("proxy"), NodeRepository.get_module_pid("pool"))
	end

	def master(exchange_list, proxy_pid, pool_pid) do
		if exchange_list != [] do
			[exchange | tail] = exchange_list
			if exchange != nil do
				send(pool_pid, {:request_worker})
			end
			receive do
				{:receive_worker, worker} -> DebugLogger.print("[MASTER] Got worker #{inspect(worker)} -> will monitor #{inspect(exchange_list)} ")													
											send(proxy_pid, {exchange, worker})
											DebugLogger.print("[MASTER] Remaining exchanges: #{inspect(tail)}")
											master(tail, proxy_pid, pool_pid)
				{:no_workers} -> DebugLogger.print("There is no enough workers. Wait and try again...")
									Process.sleep(10000)

				{:worker_down, exchange} -> DebugLogger.print("Scrapper for #{inspect(exchange)} went down. Requesting other worker...")
											master(exchange_list ++ exchange, proxy_pid, pool_pid)
			end
		end
		master(exchange_list, proxy_pid, pool_pid)
	end
	
end


