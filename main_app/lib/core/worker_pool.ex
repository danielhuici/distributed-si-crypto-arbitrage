defmodule Core.WorkerPool do
	@behaviour DistributedModule
	def add_worker(worker, lista) do
	IO.inspect lista, label: "[POOL] List add:"
		lista ++ [worker]
	end
	
	def init() do
		IO.puts("[POOL] Strarted")
		listen(Nodes.get_worker_list())
	end

	def pop_worker(list) do
		IO.puts("[POOL] List status #{inspect(list)}")
		tuple = List.pop_at(list, 0) # {%{worker}, [remaining_workers]}
		worker = elem(tuple, 0)
		if worker != nil do
			IO.puts("[POOL] Pop worker from list #{inspect(worker)}")
			send(Nodes.get_pid(:master), {:receive_worker, Nodes.get_pid(worker.name)})
			elem(tuple, 1)
		else 
			send(Nodes.get_pid(:master), {:no_workers})
			[]
		end

	end
		
	def listen(list) do
		receive do
			{:aniadir, worker} -> listen(add_worker(worker, list))
			{:request_worker} -> listen(pop_worker(list))			  
			_-> IO.puts("Error")
		end
	end
end