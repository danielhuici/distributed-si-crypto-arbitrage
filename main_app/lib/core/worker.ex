defmodule Core.Worker do
	@behaviour DistributedModule
	def init() do
		IO.puts("[WORKER] Started")
		wait_call()
	end

	defp wait_call() do
		receive do
			{:req, {proxy_pid, exchange}} -> exchange_factory(exchange)
											 handle_monitor(proxy_pid)
			{:available, pid} -> IO.puts("Available. #{inspect(pid)}")
								 send(pid, {:available})
								 wait_call()		 
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