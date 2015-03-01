.PHONY: test test_lua test_python

test_lua:
	@echo "Testing lua..."
	@busted

test_python:
	@echo "Testing python..."
	@py.test

test: test_lua test_python
