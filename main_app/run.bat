start iex --name none@127.0.0.1 --cookie testing
start mix run -e "Worker.init("worker", "worker@127.0.0.1", "testing", :"master@127.0.0.1")"
start mix run -e "Worker.init("worker2", "worker2@127.0.0.1", "testing", :"master@127.0.0.1")"
start mix run -e "WorkerPool.init("pool", "pool@127.0.0.1", "testing")"
start mix run -e "Proxy.init("proxy", "proxy@127.0.0.1", "testing", :"pool@127.0.0.1", :"master@127.0.0.1")"
start mix run -e "Calculator.init(:basic_strategy, "calculator", "calculator@127.0.0.1", "testing")"

timeout -t 10
start mix run -e "Master.init("master", "master@127.0.0.1", "testing", :"proxy@127.0.0.1", :"pool@127.0.0.1")"
