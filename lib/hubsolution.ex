defmodule Hubsolution do
  use HTTPotion.Base

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
  
  # githup reply:
  # [[repo1], [repo2], [repo3]]
  # where repoN looks like:
  # {"id", "123589"}, {"foo", "bar}, ...
  # ->
  # [id: "123455", foo: "bar]
end
