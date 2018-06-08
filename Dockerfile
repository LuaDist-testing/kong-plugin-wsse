FROM kong:0.12.1

RUN yum install -y gcc git zip unzip postgresql

RUN luarocks install date 2.1.2-1
RUN luarocks install inspect 3.1.1-0
RUN luarocks install lbase64 20120820-1
RUN luarocks install sha1 0.5-1
RUN luarocks install uuid 0.2-1

RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/CET /etc/localtime

ENV PATH=$PATH:/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx:/usr/local/openresty/nginx/sbin

RUN git clone https://github.com/Kong/kong
RUN cd kong && git checkout 0.12.1
RUN cd kong && make dev

EXPOSE 8000 8001 8443 8444

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/kong/bin/kong", "start", "--v"]
