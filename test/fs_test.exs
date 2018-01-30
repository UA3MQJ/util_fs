defmodule UtilFS.Test do
  require Logger
  use ExUnit.Case

  alias UtilFS, as: FS

  @bucket "test-bucket"
  @src_file "priv/testfile.txt"

  test "check_file()" do
    file_in_root = "file_in_root.test"
    file_in_directory = "directory/file.test"

    assert FS.check_file({@bucket, file_in_root}) == :not_found
    assert FS.check_file({@bucket, file_in_directory}) == :not_found

    FS.put_file_body({@bucket, file_in_root, "never mind"})
    {:ok, check_result} = FS.check_file({@bucket, file_in_root})
    assert is_bitstring(check_result)

    FS.put_file_body({@bucket, file_in_directory, "never mind"})
    {:ok, check_result} = FS.check_file({@bucket, file_in_directory})
    assert is_bitstring(check_result)

    clear_bucket(@bucket, [file_in_root, file_in_directory])
  end

  test "upload_file!()" do
    assert File.exists?(@src_file)
    path_to_upload_file = "upload_file.test"

    assert FS.check_file({@bucket, path_to_upload_file}) == :not_found

    FS.upload_file!(@src_file, {@bucket, path_to_upload_file})

    {:ok, check_result} = FS.check_file({@bucket, path_to_upload_file})
    assert is_bitstring(check_result)

    clear_bucket(@bucket, [path_to_upload_file])
  end

  test "get_file!()" do
    refute File.exists?("priv/testDownload")

    file = "/get_file.test"
    FS.put_file_body({@bucket, file, "never mind"})

    FS.get_file!({@bucket, file}, "priv/testDownload")
    assert File.exists?("priv/testDownload")

    clear_bucket(@bucket, [file])
    File.rm_rf!("priv/testDownload")
  end

  test "make_file_uri!()" do
    file = "make_file_uri.test"
    FS.put_file_body({@bucket, file, "never mind"})

    file_uri = FS.make_file_uri!({@bucket, file})
    assert is_bitstring(file_uri)

    clear_bucket(@bucket, [file])
  end

  test "ls_path()" do
    file1 = "/dir1/file1.test"
    file2 = "/dir1/dir2/file2.test"

    assert FS.ls_path({@bucket, "/dir1"}) == {:ok, []}

    FS.put_file_body({@bucket, file1, "never mind"})
    FS.put_file_body({@bucket, file2, "never mind"})

    assert FS.ls_path({@bucket, "/dir1"}) == {:ok, [file2, file1]}
    assert FS.ls_path({@bucket, "/dir1/dir2"}) == {:ok, [file2]}

    clear_bucket(@bucket, [file1, file2])
  end

  test "get_file_body()" do
    file = "get_file_body.test"
    body = "test"

    assert FS.check_file({@bucket, file}) == :not_found
    refute FS.get_file_body({@bucket, file}) == {:error, body}

    FS.put_file_body({@bucket, file, body})
    {:ok, check_result} = FS.check_file({@bucket, file})
    assert is_bitstring(check_result)

    assert FS.get_file_body({@bucket, file}) == {:ok, body}

    clear_bucket(@bucket, [file])
  end

  test "put_file_body()" do
    file = "put_file_body.test"
    body = "test"

    assert FS.check_file({@bucket, file}) == :not_found
    assert FS.put_file_body({@bucket, file, body}) == :ok
    assert FS.get_file_body({@bucket, file}) == {:ok, body}

    clear_bucket(@bucket, [file])
  end

  test "bucket_file_copy()" do
    src_file = "bucket_file_copy1.test"
    dest_file = "bucket_file_copy2.test"
    body = "test"

    assert FS.check_file({@bucket, src_file}) == :not_found
    assert FS.put_file_body({@bucket, src_file, body}) == :ok
    assert FS.get_file_body({@bucket, src_file}) == {:ok, body}


    assert FS.check_file({@bucket, dest_file}) == :not_found
    assert FS.bucket_file_copy({@bucket, src_file, dest_file}) == :ok
    assert FS.get_file_body({@bucket, dest_file}) == {:ok, body}

    clear_bucket(@bucket, [src_file, dest_file])
  end

  test "delete_file()" do
    file = "delete_file.test"

    assert FS.check_file({@bucket, file}) == :not_found

    FS.put_file_body({@bucket, file, "never mind"})
    {:ok, check_result} = FS.check_file({@bucket, file})
    assert is_bitstring(check_result)

    assert FS.delete_file({@bucket, file}) == :ok
    assert FS.check_file({@bucket, file}) == :not_found
  end

  defp clear_bucket(bucket, files) do
    Enum.each(files, fn(file) -> FS.delete_file({bucket, file}) end)
    ExAws.S3.delete_bucket(bucket) |> ExAws.request()
  end
end
