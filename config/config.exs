use Mix.Config

config :util_fs, :options,
      fs_type: :minio,
      # aws parameters
      access_key_id: "XXXXXXXXXXX",
      secret_access_key: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      region: "us-east-1",
      s3_scheme: "http://",
      s3_host: "127.0.0.1",
      s3_port: 9000
