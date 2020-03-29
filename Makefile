.PHONY: build
build:
	docker-compose run --rm hugo -D

.PHONY: new-post
new-post:
	script/new-post

.PHONY: server
server:
	docker-compose up hugo-server
