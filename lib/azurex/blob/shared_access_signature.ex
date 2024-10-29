defmodule Azurex.Blob.SharedAccessSignature do
  @moduledoc """
  Implements shared access signatures (SAS) on Blob Storage resources.

  Based on:
  https://learn.microsoft.com/en-us/rest/api/storageservices/create-service-sas
  """

  @doc """
  Generates a SAS url on a resource in a given container.

  ## Params
  - container: the storage container name
  - resource: the path to the resource (blob, container, directory...)
  - opts: an optional keyword list with following options
    - resource_type: one of :blob / :blob_version / :blob_snapshot / :container / directory
      Defaults to :container
    - permissions: a list of permissions. Defaults to [:read]
    - from: a tuple to defined when the SAS url validity begins. Defaults to `now`.
    - expiry: a tuple to set how long before the SAS url expires. Defaults to `{:second, 3600}`.

  ## Examples
  - `SharedAccessSignature.sas_url("my_container", "/", permissions: [:write], expiry: {:day, 2})`
  - `SharedAccessSignature.sas_url("my_container", "foo/song.mp3", resource_type: :blob)`
  """
  @spec sas_url(String.t(), String.t(), [{atom(), any()}]) :: String.t()
  def sas_url(container, resource, opts \\ []) do
    base_url = Azurex.Blob.Config.api_url()
    resource_type = Keyword.get(opts, :resource_type, :container)
    permissions = Keyword.get(opts, :permissions, [:read])
    from = Keyword.get(opts, :from, DateTime.utc_now())
    expiry = Keyword.get(opts, :expiry, {:second, 3600})
    resource = Path.join(container, resource)

    token =
      build_token(
        resource_type,
        resource,
        {from, expiry},
        permissions,
        Azurex.Blob.Config.storage_account_name(),
        Azurex.Blob.Config.storage_account_key()
      )

    "#{Path.join(base_url, resource)}?#{token}"
  end

  defp build_token(
         resource_type,
         resource,
         {from, expiry},
         permissions,
         storage_account_name,
         storage_account_key
       ) do
    URI.encode_query(
      sv: sv(),
      st: st(from),
      se: se(from, expiry),
      sr: sr(resource_type),
      sp: sp(permissions),
      sig:
        signature(
          resource_type,
          resource,
          {from, expiry},
          permissions,
          storage_account_name,
          storage_account_key
        )
    )
  end

  defp signature(
         resource_type,
         resource,
         {from, expiry},
         permissions,
         storage_account_name,
         storage_account_key
       ) do
    signature =
      Enum.join(
        [
          sp(permissions),
          st(from),
          se(from, expiry),
          canonicalized_resource(resource, storage_account_name),
          "",
          "",
          "",
          sv(),
          sr(resource_type),
          "",
          "",
          "",
          "",
          "",
          "",
          ""
        ],
        "\n"
      )

    :crypto.mac(:hmac, :sha256, storage_account_key, signature) |> Base.encode64()
  end

  defp sv, do: "2020-12-06"

  defp st(date_time), do: date_time |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  defp se(date_time, {unit, amount}),
    do:
      date_time
      |> DateTime.add(amount, unit)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

  @permissions_order ~w(r a c w d x l t m e o p)
  defp sp(permissions) do
    permissions
    |> Enum.map(fn
      :read -> "r"
      :add -> "a"
      :create -> "c"
      :write -> "w"
      :delete -> "d"
      :delete_version -> "x"
      :permanent_delete -> "y"
      :list -> "l"
      :tags -> "t"
      :find -> "f"
      :move -> "m"
      :execute -> "e"
      :ownership -> "o"
      :permissions -> "p"
      :set_immutability_policy -> "i"
    end)
    |> Enum.sort_by(fn p -> Enum.find_index(@permissions_order, &(&1 == p)) end)
    |> Enum.join("")
  end

  defp sr(:blob), do: "b"
  defp sr(:blob_version), do: "bv"
  defp sr(:blob_snapshot), do: "bs"
  defp sr(:container), do: "c"
  defp sr(:directory), do: "d"

  defp canonicalized_resource(resource, storage_account_name) do
    Path.join(["/blob", storage_account_name, resource])
  end
end
