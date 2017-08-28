use Mix.Config

config :util_fs,
  options: %{
      fs_type: :minio,
      # aws parameters
      access_key_id: "61GSNQMM34PSYHOYHFNE",
      secret_access_key: "6RzKRkRaEvCwsW5KuEcM9RT0s9jJwNHBwWaEqUqB",
      region: "us-east-1",
      s3_scheme: "http://",
      s3_host: "127.0.0.1",
      s3_port: 9000
  }
