defmodule Hubsolution do
  use HTTPotion.Base

  @root_dir "hubsolution_repos" # change me

  @github_api_url "https://api.github.com"
  @github_owner_tag "login"

  @git_command "git"
  @git_dir ".git"
  @git_dir_flag "--git-dir="
  @git_work_tree_flag "--work-tree="
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
    to_string(body) |> JSON.decode |> elem 1
  end

  @doc """
  Returns a list of Repo records from the raw github data
  """
  def repos(user) do
    options = [headers: ["User-Agent": "Hubsolution"]]
    Enum.map(get("/users/" <> user <> "/repos", options).body,
              &keys_to_atoms(&1))
    |> Enum.map &raw_to_repo(&1)
  end

  defp keys_to_atoms(contents) do
    Enum.map contents, fn({k, v}) -> {String.to_atom(k), v} end
  end

  def raw_to_repo(raw) do
    owner = extract_owner_name(raw[:owner])
    %Repo{owner: owner, name: raw[:name], description: raw[:description],
          ssh_url: raw[:ssh_url], url: raw[:html_url],
          updated_at: raw[:updated_at], fork: raw[:fork]}
  end

  def extract_owner_name(raw) do
    raw[@github_owner_tag]
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
      Path.join([@root_dir, repo.owner, repo.name]) |> do_backup repo
    end
  end

  defp do_backup(into_dir, repo) do
    cond do
      File.dir? Path.join(into_dir, @git_dir) -> update(into_dir)
      true -> clone(into_dir, repo.ssh_url)
    end
  end

  defp update(into_dir) do
    gitdir = @git_dir_flag <> Path.join(into_dir, @git_dir)
    workdir = @git_work_tree_flag <> into_dir
    run_git_command([gitdir, workdir, @git_fetch, @git_fetch_flags])
    run_git_command([gitdir, workdir, @git_reset, @git_reset_flags])
  end

  defp clone(into_dir, ssh_url) do
    run_git_command([@git_clone, @git_clone_flags, ssh_url, into_dir])
  end

  defp run_git_command(cmd) do
    git = System.find_executable(@git_command)
    command = Enum.join [git | cmd], " "
    IO.puts "Running: [" <> command <> "] in: " <> File.cwd!
    System.cmd(git, cmd)
  end

  def is_fork?(repo), do: repo.fork

  def backup_skip_forks(user) do
    reps = repos(user) |> Enum.reject(&is_fork?(&1))
    Enum.map(reps, &do_parallel_backup(&1, self))
    collect_results(length(reps), [])
  end

  defp do_parallel_backup(repo, parent_pid) do
    spawn_link(fn ->
      Path.join([@root_dir, repo.owner, repo.name]) |> do_backup repo
      send parent_pid, { String.to_atom(repo.name), :ok }
    end)
  end

  defp collect_results(0, acc), do: acc
  defp collect_results(count, acc) do
    receive do
      { repo, :ok } ->
        collect_results(count - 1, [repo|acc])
      _ ->
        collect_results(count, acc)
      after
        5000 ->
          collect_results(count, acc)
    end
  end
end
