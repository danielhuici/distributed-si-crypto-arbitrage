start iex --name none@127.0.0.1 --cookie TESTING
start mix run -e "Core.Initializer.register_and_launch(:pool, "pool@127.0.0.1", &Core.WorkerPool.init/0)"
start mix run -e "Core.Initializer.register_and_launch(:proxy, "proxy@127.0.0.1", &Core.Proxy.init/0)"
start mix run -e "Core.Initializer.register_and_launch(:calculator, "calculator@127.0.0.1", &Core.Calculator.init/0)"
start mix run -e "Core.Initializer.register_and_launch(:worker, "worker@127.0.0.1", &Core.Worker.init/0)"
start mix run -e "Core.Initializer.register_and_launch(:worker1, "worker1@127.0.0.1", &Core.Worker.init/0)"
timeout /t 10
start mix run -e "Core.Initializer.register_and_launch(:master, "master@127.0.0.1", &Core.Master.init/0)"