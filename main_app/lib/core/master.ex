defmodule Core.Master do
	@behaviour DistributedModule
	def init() do
		IO.puts("[MASTER] Wait till rest of modules gets ready...")
		Process.sleep(10000)
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
				{:no_workers} -> IO.puts("There is no enough workers. Wait and try again...")
									Process.sleep(10000)

				{:worker_down, exchange} -> IO.puts("Scrapper for #{inspect(exchange)} went down. Requesting other worker...")
											master(exchange_list ++ exchange)
			end
		end
		master(exchange_list)
	end
	
end


