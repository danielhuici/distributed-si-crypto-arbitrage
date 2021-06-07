defmodule NodeRepository do
    @cookie :testing

    defp mysql_connection() do
        {:ok, pid} = MyXQL.start_link(username: Application.fetch_env!(:tfg, :MYSQL_USERNAME),
                                      password: Application.fetch_env!(:tfg, :MYSQL_PASSWORD),
                                      database: Application.fetch_env!(:tfg, :MYSQL_DATABASE),
                                      hostname: Application.fetch_env!(:tfg, :MYSQL_HOSTNAME))
        pid
    end

    def get_modules() do
        {:ok, hostname} = :inet.gethostname
        IO.puts("[NODE REPOSITORY] Hostname: #{inspect(hostname)}")
		modules =  query_mysql("SELECT name, address FROM modules WHERE id_host IN (SELECT id FROM hosts WHERE hostname='#{hostname}')")
        modules.rows
    end

    def get_workers() do
        {:ok, hostname} = :inet.gethostname
        workers = query_mysql("SELECT name, address FROM workers WHERE id_host IN (SELECT id FROM hosts WHERE hostname='#{hostname}')")
        workers.rows
    end

    def get_module_pid(module) do        
        result =  query_mysql("SELECT address FROM modules WHERE name='#{module}'")
        {String.to_atom(module), String.to_atom(List.first(List.first(result.rows)))}
    end

    def get_cookie() do @cookie end

    defp query_mysql(query) do
        result = try do
            result = MyXQL.query!(mysql_connection(), query)
            DebugLogger.print("[MySQL] OK")
            result
        rescue
            DBConnection.ConnectionError -> 
                            DebugLogger.print("[MySQL] Query failed. Trying again...")
                            Process.sleep(1000)
                            query_mysql(query)
        end
        result
    end

end