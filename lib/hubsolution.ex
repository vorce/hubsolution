defmodule Hubsolution do
  use HTTPotion.Base

  @root_dir "hubsolution_repos"

  defrecord Repo,
    owner: "",
    name: "",
    description: "",
    ssh_url: "",
    url: "",
    updated_at: nil,
    fork: false

  @github_api_url "https://api.github.com"
  @github_owner_tag "login"

  @git_command "git"
  @git_clone "clone"
  @git_clone_flags "--recursive" # could add --mirror here if wanted

  @git_fetch "fetch"
  @git_fetch_flags "--all"
  @git_reset "reset"
  @git_reset_flags "--hard origin/master"

  def process_url(url) do
    @github_api_url <> url
  end

  def process_response_body(body) do
    to_string(body) |> JSEX.decode |> elem 1
  end

  @doc """
  Returns a list of Repo records from the raw github data
  """
  def repos(user) do
    Enum.map(get("/users/" <> user <> "/repos").body,
              fn(c) -> string_to_atom(c) end)
    |>
    Enum.map fn(r) -> raw_to_repo(r) end
  end

  defp string_to_atom(contents) do
    Enum.map contents, fn({k, v}) -> {binary_to_atom(k), v} end
  end

  def raw_to_repo(raw) do
    owner = extract_owner_name(raw[:owner])
    Repo[owner: owner, name: raw[:name], description: raw[:description],
          ssh_url: raw[:ssh_url], url: raw[:html_url],
          updated_at: raw[:updated_at], fork: raw[:fork]]
  end

  def extract_owner_name(raw) do
    Enum.find(raw, fn({k, _}) -> k == @github_owner_tag end) |> elem 1
  end

  def list_user_repos(user) do
    repos(user) |> IO.inspect
  end

  @doc """
    Clones repos in the list, the paths will be:
      <hubsolution root dir>/<repo owner>/<repo name>
  """
  def backup(repos) do
    Enum.each repos, fn(repo) ->
      Path.join([@root_dir, repo.owner, repo.name]) |> do_backup repo.ssh_url
    end
  end

  # Can't just clone here. Must force pull or something.
  def do_backup(into_dir, ssh_url) do
    cond do
      File.dir? into_dir -> update(into_dir)
      true -> clone(into_dir, ssh_url)
    end
  end

  def update(into_dir) do
    cwd = File.cwd!
    File.cd! into_dir
    run_git_command([@git_fetch, @git_fetch_flags])
    run_git_command([@git_reset, @git_reset_flags])
    File.cd! cwd
  end

  def clone(into_dir, ssh_url) do
    run_git_command([@git_clone, @git_clone_flags, ssh_url, into_dir])
  end

  def run_git_command(cmd) do
    git = System.find_executable(@git_command)
    command = Enum.join [git | cmd], " "
    IO.puts "Running: " <> command
    System.cmd(command)
  end
  
  # githup reply:
  # [[repo1], [repo2], [repo3]]
  # where repoN looks like:
  # {"id", "123589"}, {"foo", "bar}, ...
  # ->
  # [id: "123455", foo: "bar]
end
