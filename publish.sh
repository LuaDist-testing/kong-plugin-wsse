!#/bin/bash

luarocks make
luarocks pack kong-plugin-wsse
find . -name '*.rockspec' | xargs luarocks upload --api-key=$LUAROCKS_API_KEY
find . -name '*.all.rock' -delete
find . -name '*.src.rock' -delete