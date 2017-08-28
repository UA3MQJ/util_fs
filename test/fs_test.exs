defmodule UtilFS.Test do
  require Logger
  use ExUnit.Case

  alias UtilFS, as: FS

  setup_all do
    {:ok, %{file: "priv/testfile.txt", bucket: "test-bucket"}}
  end

  test "test module", state do
    assert File.exists?(state[:file])
    state[:bucket] |> ExAws.S3.delete_object(state[:file]) |> ExAws.request()
    state[:bucket] |> ExAws.S3.delete_bucket() |> ExAws.request()

    s3_file = {state[:bucket], state[:file]}

    check_result1 = FS.check_file(s3_file)
    assert check_result1 === :not_found

    FS.upload_file!(state[:file], s3_file)
    %{status_code: code} = state[:bucket] |> ExAws.S3.head_object(state[:file]) |> ExAws.request!()
    assert code === 200

    {:ok, check_result2} = FS.check_file(s3_file)
    assert is_bitstring(check_result2)

    file_uri = FS.make_file_uri!({state[:bucket], state[:file]})
    HTTPoison.get!(file_uri, [])

    FS.get_file!(s3_file, "priv/testDownload")
    assert File.exists?("priv/testDownload")
    File.rm_rf!("priv/testDownload")
  end

end
