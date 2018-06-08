FROM emarsys/kong-dev-docker:latest

RUN luarocks install date 2.1.2-1
RUN luarocks install inspect 3.1.1-0
RUN luarocks install lbase64 20120820-1
RUN luarocks install sha1 0.5-1
RUN luarocks install uuid 0.2-1
RUN luarocks install classic
RUN luarocks install kong-lib-logger --deps-mode=none

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/kong/bin/kong", "start", "--v"]
