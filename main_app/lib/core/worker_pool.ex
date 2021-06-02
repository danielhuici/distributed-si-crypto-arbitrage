defmodule Core.WorkerPool do
	@behaviour DistributedModule

	def init() do
		DebugLogger.print("[POOL] Strarted")
		worker_list = build_initial_worker_list(NodeRepository.get_workers, [])
		DebugLogger.print("List workers init: #{inspect(worker_list)}")
		listen(worker_list, NodeRepository.get_module_pid("master"))
	end

	defp build_initial_worker_list(worker_list, built_list) do
		built_list = if worker_list != [] do
			[worker | tail] = worker_list
			built_list = [{String.to_atom(List.first(worker)), String.to_atom(List.last(worker))} | built_list]
			build_initial_worker_list(tail, built_list)
		else
			built_list
		end
	end

	defp add_worker(worker, lista) do
	IO.inspect lista, label: "[POOL] List add:"
		lista ++ [worker]
	end
	
	defp pop_worker(list, master_pid) do
		worker = List.pop_at(list, 0)
		DebugLogger.print("[POOL] Get worker: #{inspect(worker)}")
		if elem(worker, 0) != nil do
			send(elem(worker, 0), {:available, self()})
			receive do
				{:available} -> send(master_pid, {:receive_worker, elem(worker, 0)})
				after 5_000 -> pop_worker(elem(worker, 1), master_pid)
			end
			elem(worker, 1)
		else 
			send(master_pid, {:no_workers})
			[]
		end
	end
		
	defp listen(list, master_pid) do
		receive do
			{:aniadir, worker} -> listen(add_worker(worker, list), master_pid)
			{:request_worker} -> listen(pop_worker(list, master_pid), master_pid)			  
			_-> DebugLogger.print("Error")
		end
	end
end