defmodule Mix.Tasks.RunHubsolution do
  use Mix.Task

  @shortdoc "Run Hubsolution"

  def run(args) do
    Hubsolution.start
    Hubsolution.backup_skip_forks(Enum.first args)
    #App.run args
  end
end
