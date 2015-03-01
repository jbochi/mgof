.PHONY: test test_lua test_python install_dependencies install_dev

install_dev:
	pip install -r requirements-dev.txt

install_dependencies:
	pip install -r requirements.txt

test_lua:
	@echo "Testing lua..."
	@busted

test_python:
	@echo "Testing python..."
	@py.test

test: test_lua test_python
