defmodule Azurex.Authorization.ServicePrincipalTest do
  use ExUnit.Case
  doctest Azurex.Authorization.ServicePrincipal

  alias Azurex.Authorization.ServicePrincipal

  import ExUnit.CaptureLog

  setup do
    bypass = Bypass.open()

    Application.put_env(:azurex, Azurex.Blob.Config, auth_url: "http://localhost:#{bypass.port}")

    {:ok, bypass: bypass}
  end

  defp generate_token(time) do
    token = %{exp: time} |> Jason.encode!() |> Base.encode64()
    "a.#{token}"
  end

  defp generate_request do
    %HTTPoison.Request{
      method: :put,
      url: "https://example.com/sample-path",
      body: "sample body",
      headers: [
        {"x-ms-blob-type", "BlockBlob"}
      ],
      options: [recv_timeout: :infinity]
    }
  end

  defp prepare_auth_enpoint(bypass, token) do
    Bypass.expect_once(bypass, "POST", "/tenant_id/oauth2/v2.0/token", fn conn ->
      token_response = %{access_token: token} |> Jason.encode!()
      Plug.Conn.resp(conn, 200, token_response)
    end)
  end

  describe "add_bearer_token/4" do
    test "Test bearer cache", %{bypass: bypass} do
      # Set token time so it expires in 100 seconds
      t = generate_token(:os.system_time(:second) + 100)
      # Expect one token request because the second will be cached
      prepare_auth_enpoint(bypass, t)
      input_request = generate_request()

      for _ <- 1..2 do
        output_request =
          ServicePrincipal.add_bearer_token(
            input_request,
            "client_id",
            "client_secret",
            "tenant_id"
          )

        assert output_request == %HTTPoison.Request{
                 body: "sample body",
                 headers: [
                   {"Authorization", "Bearer #{t}"},
                   {"x-ms-blob-type", "BlockBlob"}
                 ],
                 method: :put,
                 options: [recv_timeout: :infinity],
                 params: %{},
                 url: "https://example.com/sample-path"
               }
      end
    end

    test "Test bearer cache refresh", %{bypass: bypass} do
      # Set token time so it expired 100 seconds ago
      t = generate_token(:os.system_time(:second) - 100)
      input_request = generate_request()

      for _ <- 1..2 do
        # Now we expect two token requests because the token is expired
        prepare_auth_enpoint(bypass, t)

        output_request =
          ServicePrincipal.add_bearer_token(
            input_request,
            "client_id",
            "client_secret",
            "tenant_id"
          )

        assert output_request == %HTTPoison.Request{
                 body: "sample body",
                 headers: [
                   {"Authorization", "Bearer #{t}"},
                   {"x-ms-blob-type", "BlockBlob"}
                 ],
                 method: :put,
                 options: [recv_timeout: :infinity],
                 params: %{},
                 url: "https://example.com/sample-path"
               }
      end
    end

    test "Failure", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/tenant_id/oauth2/v2.0/token", fn conn ->
        Plug.Conn.resp(conn, 403, "Not authorized")
      end)

      input_request = generate_request()

      {output_request, log} =
        with_log(fn ->
          ServicePrincipal.add_bearer_token(
            input_request,
            "client_id",
            "client_secret",
            "tenant_id"
          )
        end)

      assert output_request == %HTTPoison.Request{
               body: "sample body",
               headers: [
                 {"Authorization", "Bearer No token"},
                 {"x-ms-blob-type", "BlockBlob"}
               ],
               method: :put,
               options: [recv_timeout: :infinity],
               params: %{},
               url: "https://example.com/sample-path"
             }

      assert log =~ "Failed to fetch bearer token. Reason: 403: Not authorize"
    end
  end
end
