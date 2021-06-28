defmodule Webserver.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Webserver.Router, options: [port: 8080]},
    ]
    opts = [strategy: :one_for_one, name: Webserver.Supervisor]

    Logger.info("Starting Web Server...")
    Supervisor.start_link(children, opts)
  end
end

defmodule Webserver.Router do
    use Plug.Router
    use Plug.Debugger
    require Logger
	plug Plug.Static, at: "/", from: "./img"
    plug(Plug.Logger, log: :debug)
    plug(:match)
    plug(:dispatch)
	
	
	get "/register" do
		IO.puts("Testing...")
		Process.register(self(), String.to_atom("webserver"))
		Node.start(String.to_atom("webserver@127.0.0.1"))
		Node.set_cookie String.to_atom("testing")
		
		send_resp(conn, 200, "Infraestructure connection OK")
	end
	
    get "/values" do
		
		send({:calculator, :"calculator@127.0.0.1"}, {:get_values, self()})
			receive do
				{:arbitrage_values, matrix} -> send_resp(conn, 200, Jason.encode!(matrix))
				after 5_000 -> send_resp(conn, 500, "Service Unavailable")
			end
    end
	
	get "/profit-history" do
		conn = Plug.Conn.fetch_query_params(conn)
		params = conn.query_params
		
		date_init = String.split(params["date_init"], "-")
		date_end = String.split(params["date_end"], "-")
		time_init = String.split(params["time_init"], ":")
		time_end = String.split(params["time_end"], ":")
		
		
		IO.puts("Test: #{inspect(date_init)}")
		IO.puts("Test 2: #{inspect(List.pop_at(date_init, 0))}")
		
		
		date_init = Date.new(elem(Integer.parse(elem(List.pop_at(date_init, 0), 0)), 0), elem(Integer.parse(elem(List.pop_at(date_init, 1), 0)), 0), elem(Integer.parse(elem(List.pop_at(date_init, 2), 0)), 0))
		date_end = Date.new(elem(Integer.parse(elem(List.pop_at(date_end, 0), 0)), 0), elem(Integer.parse(elem(List.pop_at(date_end, 1), 0)), 0), elem(Integer.parse(elem(List.pop_at(date_end, 2), 0)), 0))
		time_init = Time.new(elem(Integer.parse(List.first(time_init)), 0), elem(Integer.parse(List.last(time_init)), 0), 0)
		time_end = Time.new(elem(Integer.parse(List.first(time_end)), 0), elem(Integer.parse(List.last(time_end)), 0), 0)
		
		datetime_init = DateTime.new(elem(date_init, 1), elem(time_init, 1))
		datetime_end = DateTime.new(elem(date_end, 1), elem(time_end, 1))
		
		IO.puts("datetime_init: #{inspect(datetime_init)}")
		IO.puts("datetime_end: #{inspect(datetime_end)}")
		send({:plotgen, :"plotgen@127.0.0.1"}, {:create_plot, String.to_atom(params["coin"]), elem(datetime_init, 1), elem(datetime_end, 1), self()})
		
		receive do
			{:ok} -> 
				try do
					Process.sleep(500)
					send_file(conn, 200, "../main_app/#{params["coin"]}.png")
				rescue
					File.Error -> send_resp(conn, 404, "File not found")
				_ -> send_resp(conn, 500, "Internal Server Error")
				end
			after 30_000 -> send_resp(conn, 500, "Service Unavailable")
		end
    end
	
	get "/support-resistances" do
		conn = Plug.Conn.fetch_query_params(conn)
		params = conn.query_params
		
		date_init = String.split(params["date_init"], "-")
		date_end = String.split(params["date_end"], "-")
		time_init = String.split(params["time_init"], ":")
		time_end = String.split(params["time_end"], ":")
		
		
		date_init = Date.new(elem(Integer.parse(elem(List.pop_at(date_init, 0), 0)), 0), elem(Integer.parse(elem(List.pop_at(date_init, 1), 0)), 0), elem(Integer.parse(elem(List.pop_at(date_init, 2), 0)), 0))
		date_end = Date.new(elem(Integer.parse(elem(List.pop_at(date_end, 0), 0)), 0), elem(Integer.parse(elem(List.pop_at(date_end, 1), 0)), 0), elem(Integer.parse(elem(List.pop_at(date_end, 2), 0)), 0))
		time_init = Time.new(elem(Integer.parse(List.first(time_init)), 0), elem(Integer.parse(List.last(time_init)), 0), 0)
		time_end = Time.new(elem(Integer.parse(List.first(time_end)), 0), elem(Integer.parse(List.last(time_end)), 0), 0)
		
		datetime_init = DateTime.new(elem(date_init, 1), elem(time_init, 1))
		datetime_end = DateTime.new(elem(date_end, 1), elem(time_end, 1))
		
		IO.puts("datetime_init: #{inspect(datetime_init)}")
		IO.puts("datetime_end: #{inspect(datetime_end)}")
		send({:supportresistances, :"supportresistances@127.0.0.1"}, {:create_plot, String.to_atom(params["coin"]), String.to_atom(params["exchange"]), elem(datetime_init, 1), elem(datetime_end, 1), self()})
		
		receive do
			{:ok} -> 
				try do
					Process.sleep(500)
					send_file(conn, 200, "../main_app/#{params["coin"]}.png")
				rescue
					File.Error -> send_resp(conn, 404, "File not found")
				_ -> send_resp(conn, 500, "Internal Server Error")
				end
			after 30_000 -> send_resp(conn, 500, "Service Unavailable")
		end
    end
	

    # Basic example to handle POST requests wiht a JSON body
    post "/post" do
        {:ok, body, conn} = read_body(conn)
        body = Poison.decode!(body)
        IO.inspect(body)
		
        send_resp(conn, 201, "created: #{get_in(body, ["message"])}")
    end


    # "Default" route that will get called when no other route is matched
    match _ do
		IO.puts("#{inspect(File.ls())}")
        send_resp(conn, 404, "not found")
    end
end
