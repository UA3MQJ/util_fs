defmodule UtilFS.Minio do
  @moduledoc """
  модуль для помощи в работе с файлами в минио
  """

  # получить файл
  require Logger
  @spec get_file!({bucket :: String.t, path :: String.t}, fs_path :: String.t) ::
    :ok | no_return
  def get_file!({bucket, path}, fs_path) do
    Logger.debug("download file #{inspect {bucket, path}}")
    bucket |> ExAws.S3.download_file(path, fs_path) |> ExAws.request!()
  end

  # проверить наличае, в случае успеха вернуть урл
  @spec check_file({bucket :: String.t, path :: String.t}) ::
    {:ok, bitstring} |
    :not_found |
    {:error, any}
  def check_file({bucket, path}) do
    case bucket |> ExAws.S3.head_object( path) |> ExAws.request() do
      {:ok, %{status_code: 200}} ->
        {:ok, make_file_uri!({bucket, path})}
      {:error, {:http_error, 404, _}} ->
        :not_found
      {:error, error} ->
        {:error, {:minio_error, inspect(error)}}
      error ->
        {:error, {:unknown_error, error}}
    end
  end

  # загрузить файл в хранилище
  @spec upload_file!(file :: String.t , {bucket :: String.t, path :: String.t}) ::
    bitstring | no_return
  def upload_file!(file, {bucket, path}) do
    bucket_result = bucket |> ExAws.S3.head_bucket() |> ExAws.request()
    # {:ok, %{status_code: 200}} = ExAws.S3.head_bucket(bucket) |> ExAws.request()
    case bucket_result do
      {:ok, %{status_code: 200}} ->
        :ok
      {:error, {:http_error, 404, _}} ->
        bucket |> ExAws.S3.put_bucket("") |> ExAws.request!()
      {:error, error} ->
        throw({:error, {:minio_error, inspect(error)}})
    end
    file_uri = make_file_uri!({bucket, path})
    file
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(bucket, path)
      |> ExAws.request!()
    file_uri
  end

  @spec upload_file(file :: String.t , {bucket :: String.t, path :: String.t}) ::
    {:ok, bitstring} |
    {:error, any}
  def upload_file(file, {bucket, path}) do
    try do
      {:ok, upload_file!(file, {bucket, path})}
    catch
      {:error, _} = error ->
        error
      error ->
        {:error, error}
    rescue
      error ->
        {:error, error}
    end
  end


  # получить ссылку на файл
  @spec make_file_uri!({bucket :: String.t, path :: String.t}) ::
    bitstring | no_return
  def make_file_uri!({bucket, path}) do
    result =
      :s3
      |> ExAws.Config.new()
      |> modify_host()
      |> ExAws.S3.presigned_url(:get, bucket, path)
    case result do
      {:ok, binary} -> binary
      {:error, error} -> throw({:error, {:make_file_uri_error, inspect(error)}})
      unknown -> throw({:error, {:unknown_error, unknown}})
    end
  end

  # список файлов в пути включая вложенности
  @spec ls_path({bucket :: String.t, path :: String.t}) :: {:ok, file_list :: list} | {:error, any}
  def ls_path({bucket, path}) do
    Logger.debug("list files in #{inspect {bucket, path}}")
    result = ExAws.S3.list_objects(bucket, prefix: path) |> ExAws.request()
    case result do
      {:ok, %{body: %{contents: contents}}} ->
        {:ok, Enum.map(contents, fn(content) -> content.key end)}
      _ -> result
    end
  end

  # получение содержимого файла
  @spec get_file_body({bucket :: String.t, path :: String.t}) :: {:ok, body :: String.t} | {:error, any}
  def get_file_body({bucket, path}) do
    Logger.debug("get file body #{inspect {bucket, path}}")
    result = ExAws.S3.get_object(bucket, path) |> ExAws.request()
    case result do
      {:ok, %{body: body}} -> {:ok, body}
      _ -> result
    end
  end

  # запись в файл
  @spec put_file_body({bucket :: String.t, path :: String.t, body :: String.t}) :: :ok | {:error, any}
  def put_file_body({bucket, path, body}) do
    Logger.debug("put file body #{inspect {bucket, path, body}}")
    result = ExAws.S3.put_object(bucket, path, body) |> ExAws.request()
    case result do
      {:ok, _} -> :ok
      _ -> result
    end
  end

  # копирование файла в бакете
  @spec bucket_file_copy({bucket :: String.t, src_path :: String.t, dest_path :: String.t}) :: :ok | {:error, any}
  def bucket_file_copy({bucket, src_path, dest_path}) do
    Logger.debug("copy file #{inspect {bucket, src_path, dest_path}}")
    result = ExAws.S3.put_object_copy(bucket, dest_path, bucket, src_path) |> ExAws.request()
    case result do
      {:ok, _} -> :ok
      _ -> result
    end
  end

  # удаление файла
  @spec delete_file({bucket :: String.t, path :: String.t}) :: :ok | {:error, any}
  def delete_file({bucket, path}) do
    Logger.debug("delete file #{inspect {bucket, path}}")
    result = ExAws.S3.delete_object(bucket, path) |> ExAws.request()
    case result do
      {:ok, _} -> :ok
      _ -> result
    end
  end

  defp modify_host(s3_config) do
    try do
      host = s3_config[:host]
      port = s3_config[:port]
      {:ok, _} = :inet_parse.address(String.to_charlist(host))
      true = is_integer(port)
      %{s3_config | host: "#{host}:#{port}"}
    rescue
      e ->
        st = System.stacktrace()
        Logger.debug("#{inspect self()} host not modified #{inspect e}: #{inspect st}")
        s3_config
    end
  end
end
