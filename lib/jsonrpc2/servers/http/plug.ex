defmodule JSONRPC2.Servers.HTTP.Plug do
  @moduledoc """
  A plug that responds to POSTed JSON-RPC 2.0 in the request body.

  If you wish to start a standalone server which will respond to JSON-RPC 2.0
  POSTs at any URL, please see `JSONRPC2.Servers.HTTP`.

  If you wish to mount a JSON-RPC 2.0 handler in an existing Plug-based web
  application (such as Phoenix), you can do so by putting this in your router:

      forward "/jsonrpc", JSONRPC2.Servers.HTTP.Plug, YourJSONRPC2HandlerModule

  The above code will mount the handler `YourJSONRPC2HandlerModule` at the path
  "/jsonrpc".
  """

  @doc false
  def init(handler) do
    handler
  end

  @doc false
  def call(%{method: "POST"} = conn, handler) do
    req_body =
      cond do
        Plug.Conn.get_req_header(conn, "content-type")
        |> Enum.member?("application/json") && conn.params != %{} && conn.params != %Plug.Conn.Unfetched{} ->
          conn.params

        true ->
          get_plain_body(conn)
      end

    resp_body =
      case handler.handle(req_body) do
        {:reply, reply} -> reply
        :noreply -> ""
      end

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json")
    |> Plug.Conn.resp(200, resp_body)
  end

  def call(conn, _) do
    conn
    |> Plug.Conn.resp(404, "")
  end

  defp get_plain_body(conn) do
    {:ok, req_body, _} = Plug.Conn.read_body(conn)
    req_body
  end
end
