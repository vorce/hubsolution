defmodule HubsolutionTest do
  use ExUnit.Case, async: true

  alias Hubsolution.Repo, as: Repo

  @rawrepo [id: 12196274, name: "HelloWorld", full_name: "test/HelloWorld",
            owner: [{"login", "test"}, {"id", 383316}],
            html_url: "https://github.com/test/HelloWorld",
            description: "Create hello world",
            updated_at: "2013-08-18T15:55:36Z",
            ssh_url: "git@github.com:test/HelloWorld.git",
            fork: false]

  # Acceptance test
  # Note! This test requires an internet connection where you can
  # access https://api.github.com/users/test/repos
  test "Should be able to list user's repositories" do
    Hubsolution.start
    reply = Hubsolution.repos("test")
    assert length(reply) > 0,
      "Empty list of repos on github for user 'test'"
    
    repo1 = Enum.first reply
    assert repo1.owner == "test",
      "First repo's owner does not match 'test'"
  end

  test "Raw repo to record" do
    expected = Repo[owner: "test", name: "HelloWorld",
                    description: "Create hello world",
                    ssh_url: "git@github.com:test/HelloWorld.git",
                    url: "https://github.com/test/HelloWorld",
                    updated_at: "2013-08-18T15:55:36Z",
                    fork: false]
    assert Hubsolution.raw_to_repo(@rawrepo) == expected
  end

  test "Should extract owner from raw" do
    assert Hubsolution.extract_owner_name(@rawrepo[:owner]) == "test"
  end

  # Acceptance test
  test "Should clone non-existing repos locally" do
    File.rm_rf("hubsolution_repos")
    Hubsolution.repos("test") |> Hubsolution.backup
    assert File.dir? "hubsolution_repos",
      "'hubsolution_repos' dir wasn't created"
  end
end
