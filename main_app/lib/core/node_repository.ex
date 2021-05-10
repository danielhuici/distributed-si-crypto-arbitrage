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
		modules = MyXQL.query!(mysql_connection(), "SELECT name, address FROM modules WHERE id_host IN (SELECT id FROM hosts WHERE hostname='#{hostname}')")
        modules.rows
    end

    def get_workers() do
        {:ok, hostname} = :inet.gethostname
        workers = MyXQL.query!(mysql_connection(), "SELECT name, address FROM workers WHERE id_host IN (SELECT id FROM hosts WHERE hostname='#{hostname}')")
        workers.rows
    end

    def get_module_pid(module) do        
        result = MyXQL.query!(mysql_connection(), "SELECT address FROM modules WHERE name='#{module}'")
        {String.to_atom(module), String.to_atom(List.first(List.first(result.rows)))}
    end

    def get_cookie() do @cookie end

end