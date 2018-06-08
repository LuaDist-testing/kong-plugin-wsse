SHELL=/bin/bash
.PHONY: help publish

help: ##                 Show this help
	@echo "Targets:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/\(.*\):.*##[ \t]*/    \1 ## /' | sort | column -t -s '##'

publish: ##                 Build and publish plugin to luarocks
	docker-compose run kong bash -c "cd /kong-plugins && chmod +x publish.sh && ./publish.sh"
