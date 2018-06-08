# Kong WSSE Plugin

## Install
 - clone the git repo
 - enter to the directory
 - cp env.sample env
 - write the luarock api key to env file (from secret server)

## Running tests from project folder:

`make test`

## Publish new release
 - rename rockspec file to the new version
 - change then version and source.tag in rockspec file
 - commit the changes
 - create a new tag (ex.: git tag 0.1.0)
 - push the changes with the tag (git push --tag)
 - `make publish`
 
## Create dummy data on Admin API

- `make dev-env`

## Access local DB

- `make ssh`
- `cd kong-plugins`
- `make db`