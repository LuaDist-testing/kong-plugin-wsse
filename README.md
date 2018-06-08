# Kong WSSE Plugin

## Install
 - clone the git repo
 - enter to the directory
 - cp env.sample env
 - write the luarock api key to env file (from secret server)

## Running tests from project folder:
`docker-compose run kong bash -c "cd /kong && bin/busted /kong-plugins/spec"`

## Publish new release
 - rename rockspec file to the new version
 - change then version and source.tag in rockspec file
 - commit the changes
 - create a new tag (ex.: git tag 0.1.0)
 - push the changes with the tag (git push --tag)
 
## Create dummy data on Admin API

### Add test API
`curl -i -X POST --url http://localhost:8001/apis/ --data 'name=testapi' --data 'upstream_url=http://mockbin.org/request' --data 'uris=/'`

### Register WSSE Plugin on test API
`curl -i -X POST --url http://localhost:8001/apis/testapi/plugins/ --data 'name=wsse'`

### Add consumer
`curl -i -X POST --url http://localhost:8001/consumers/ --data "username=TestUser"`

### Add WSSE key to consumer 
`curl -i -X POST --url http://localhost:8001/consumers/TestUser/wsse_key/ --data 'key=test_user001&secret=53cr37p455w0rd'`

## Access local DB

- `docker-compose up`
- `docker-compose run kong bash`
- `psql -h kong-database -U kong`