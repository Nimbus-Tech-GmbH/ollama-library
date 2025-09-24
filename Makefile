.PHONY: dev prod test lint format clean

dev:
	poetry run uvicorn ollama_library.main:app --reload

prod:
	poetry run uvicorn ollama_library.main:app --host 0.0.0.0 --port 8000

test:
	poetry run pytest

test-coverage:
	poetry run pytest --cov=ollama_library --cov-report=term-missing

lint:
	poetry run flake8 src/ollama_library tests

format:
	poetry run black src/ollama_library tests

clean:
	find . -type d -name '__pycache__' -exec rm -rf {} +
	find . -type d -name '.pytest_cache' -exec rm -rf {} +
