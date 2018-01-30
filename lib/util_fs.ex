defmodule UtilFS do
  use Application
  require Logger

  def start(_type, _args) do
    Confex.resolve_env!(:util_fs)
    param = get_options()

    Application.put_env(:ex_aws, :access_key_id, param.access_key_id)
    Application.put_env(:ex_aws, :secret_access_key, param.secret_access_key)
    Application.put_env(:ex_aws, :region, param.region)
    Application.put_env(:ex_aws, :s3, [
                                        scheme: param.s3_scheme,
                                        host: param.s3_host,
                                        port: param.s3_port
                                      ])

    {:ok, self()}
  end

  def get_options() do
    Application.get_env(:util_fs, :options)
    |> Enum.into(%{})
  end

  # API
  # проверить наличае, в случае успеха вернуть урл
  @spec check_file({bucket :: String.t, path :: String.t}) ::
    {:ok, bitstring} |
    :not_found |
    {:error, any}
  def check_file({bucket, path}) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.check_file({bucket, path})
      _else -> fs_type_error()
    end
  end

  # загрузить файл в хранилище
  @spec upload_file!(file :: String.t , {bucket :: String.t, path :: String.t}) ::
    bitstring | no_return
  def upload_file!(file, {bucket, path}) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.upload_file!(file, {bucket, path})
      _else -> fs_type_error()
    end
  end

  # получить файл
  require Logger
  @spec get_file!({bucket :: String.t, path :: String.t}, fs_path :: String.t) ::
    :ok | no_return
  def get_file!({bucket, path}, fs_path) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.get_file!({bucket, path}, fs_path)
      _else -> fs_type_error()
    end
  end

  # получить ссылку на файл
  @spec make_file_uri!({bucket :: String.t, path :: String.t}) ::
    bitstring | no_return
  def make_file_uri!({bucket, path}) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.make_file_uri!({bucket, path})
      _else -> fs_type_error()
    end
  end

  # список файлов в пути включая вложенности
  @spec ls_path({bucket :: String.t, path :: String.t}) :: {:ok, result :: list} | {:error, any}
  def ls_path({bucket, path}) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.ls_path({bucket, path})
      _else -> fs_type_error()
    end
  end

  # получение содержимого файла
  @spec get_file_body({bucket :: String.t, path :: String.t}) :: {:ok, body :: String.t} | {:error, any}
  def get_file_body({bucket, path}) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.get_file_body({bucket, path})
      _else -> fs_type_error()
    end
  end

  # запись в файл
  @spec put_file_body({bucket :: String.t, path :: String.t, body :: String.t}) :: :ok | {:error, any}
  def put_file_body({bucket, path, body}) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.put_file_body({bucket, path, body})
      _else -> fs_type_error()
    end
  end

  # копирование файла в бакете
  @spec bucket_file_copy({bucket :: String.t, src_path :: String.t, dest_path :: String.t}) :: :ok | {:error, any}
  def bucket_file_copy({bucket, src_path, dest_path}) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.bucket_file_copy({bucket, src_path, dest_path})
      _else -> fs_type_error()
    end
  end

  # удаление файла
  @spec delete_file({bucket :: String.t, path :: String.t}) :: :ok | {:error, any}
  def delete_file({bucket, path}) do
    utils_opt = get_options()
    case utils_opt.fs_type do
      :minio -> UtilFS.Minio.delete_file({bucket, path})
      _else -> fs_type_error()
    end
  end

  defp fs_type_error(), do: {:error, :unknown_fs_type}
end
