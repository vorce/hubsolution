# Hubsolution

Hubsolution backs up / copies a specified Github user's repositories.
By default Hubsolution does not include forks.


## Requires

`git` installed and on your PATH


## Run it

    mix compile
    mix runHubsolution myuser


## Depends on

- HTTPotion: https://github.com/myfreeweb/httpotion.git
- Jsex: https://github.com/talentdeficit/jsex.git

## TODO

- Add config
- Instead of Jsex, use https://github.com/cblage/elixir-json
- Parallelize the update of a repo

