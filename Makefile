.PHONY: build
build:
	docker-compose run --rm hugo -D

.PHONY: server
hugo-server:
	docker-compose up hugo-server
