defmodule Core.WorkerPool do
	@behaviour DistributedModule

	def init() do
		IO.puts("[POOL] Strarted")
		worker_list = build_initial_worker_list(NodeRepository.get_workers, [])
		IO.puts("List workers init: #{inspect(worker_list)}")
		listen(worker_list)
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
	
	defp pop_worker(list) do
		IO.puts("[POOL] List status #{inspect(list)}")
		worker = List.pop_at(list, 0)
		IO.puts("[POOL] Worker: #{inspect(worker)}")
		if elem(worker, 0) != nil do
			send(elem(worker, 0), {:available, self()})
			receive do
				{:available} -> IO.puts("[POOL] Pop worker from list #{inspect(worker)}")
										send(NodeRepository.get_module_pid("master"), {:receive_worker, elem(worker, 0)})
				after 5_000 -> pop_worker(elem(worker, 1))
			end
			elem(worker, 1)
		else 
			send(NodeRepository.get_module_pid("master"), {:no_workers})
			[]
		end
	end
		
	defp listen(list) do
		receive do
			{:aniadir, worker} -> listen(add_worker(worker, list))
			{:request_worker} -> listen(pop_worker(list))			  
			_-> IO.puts("Error")
		end
	end
end