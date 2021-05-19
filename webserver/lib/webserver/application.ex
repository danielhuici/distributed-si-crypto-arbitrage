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
	
	

	
    get "/values" do
		IO.puts("Testing...")
		Process.register(self(), String.to_atom("webserver"))
		Node.start(String.to_atom("webserver@127.0.0.1"))
		Node.set_cookie String.to_atom("testing")

		
		send({:calculator, :"calculator@127.0.0.1"}, {:get_values, self()})
			receive do
				{:arbitrage_values, matrix} -> send_resp(conn, 200, Jason.encode!(matrix))
				after 5_000 -> send_resp(conn, 500, "Service Unavailable")
			end
    end
	
	get "/images" do
		conn = Plug.Conn.fetch_query_params(conn)
		params = conn.query_params
		try do
			send_file(conn, 200, "../main_app/#{params["coin"]}.png")
		rescue
			File.Error -> send_resp(conn, 404, "File not found")
			_ -> send_resp(conn, 500, "Internal Server Error")
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
