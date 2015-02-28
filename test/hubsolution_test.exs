defmodule HubsolutionTest do
  use ExUnit.Case#, async: true

  setup_all do
    Hubsolution.start

    on_exit fn ->
      File.rm_rf("hubsolution_repos")
    end

    :ok
  end

  setup do
    File.rm_rf("hubsolution_repos")
    repo = [id: 39790, name: "haml-test", full_name: "testuser/haml-test",
            owner: %{"login" => "testuser", "id" => 19480},
            html_url: "https://github.com/testuser/haml-test",
            description: "Create hello world",
            updated_at: "2013-08-18T15:55:36Z",
            ssh_url: "git@github.com:testuser/haml-test.git",
            fork: false]
    {:ok, repo: repo}
  end

  # Note! Many of these tests are not unit tests, but rather
  # integration tests.
  # This test requires an internet connection where you can
  # access https://api.github.com/users/test/repos
  test "Should be able to list user's repositories" do
    reply = Hubsolution.repos("testuser")
    assert length(reply) > 0,
      "Empty list of repos on github for user 'testuser'"
    
    repo1 = hd reply
    assert repo1.owner == "testuser",
      "First repo's owner does not match 'test'"
  end

  test "Raw repo to record", context do
    expected = %Repo{owner: "testuser", name: "haml-test",
                    description: "Create hello world",
                    ssh_url: "git@github.com:testuser/haml-test.git",
                    url: "https://github.com/testuser/haml-test",
                    updated_at: "2013-08-18T15:55:36Z",
                    fork: false}
    assert Hubsolution.raw_to_repo(context[:repo]) == expected
  end

  test "Should extract owner from raw", context do
    owner = Hubsolution.extract_owner_name(context[:repo][:owner])
    assert owner == "testuser"
  end

  test "Should clone non-existing repos locally" do
    repos = Hubsolution.repos("testuser")
    Hubsolution.backup(repos)
    assert File.dir?("hubsolution_repos"),
      "'hubsolution_repos' dir wasn't created"
  end

  test "Should clone test repo", context do
    repo = Hubsolution.raw_to_repo(context[:repo])
    Hubsolution.backup([repo])
    assert File.dir?("hubsolution_repos/testuser/haml-test/.git"),
      "Expected dir 'hubsolution_repos/testuser/haml-test/.git' to exist"
  end

  test "Should detect forked repos", context do
    repo = Hubsolution.raw_to_repo(context[:repo])
    assert Hubsolution.is_fork?(repo) == false
  end
end
