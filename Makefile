.phony:

env:
	export $(cat .env | xargs)

watch:
		@echo "Watching for changes..."
		cargo watch -s 'mold -run cargo run'