.PHONY: build
build:
	docker-compose run --rm hugo -D

.PHONY: server
server:
	docker-compose up hugo-server
