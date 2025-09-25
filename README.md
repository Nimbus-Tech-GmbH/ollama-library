# ollama-library

A Python FastAPI service for scraping model names and descriptions from the Ollama Library web page and returning them as a structured JSON API.
Quickly surface and search model metadata from Ollama’s public library as an API.

## Features

- 🚀 FastAPI-based RESTful API
- 🔎 Scrapes Ollama Library for available models
- 📝 Returns data as a JSON array:
  ```
  [
    {
      "model": "model-name",
      "description": "model-description"
    }
  ]
  ```

## Quickstart

1. **Clone the repository:**
    ```
    git clone https://github.com/your-username/ollama-library.git
    cd ollama-library
    ```
2. **Install dependencies:**
    ```
    poetry install
    ```
    *(Or use `pip install -r requirements.txt` if not using Poetry)*

3. **Run the FastAPI app:**
    ```
    make dev
    ```

4. **Access the API:**
    - Visit [http://localhost:8000/scrape?url=https://ollama.ai/library](http://localhost:8000/scrape?url=https://ollama.ai/library) for the JSON response
    - Open [http://localhost:8000/docs](http://localhost:8000/docs) for interactive Swagger documentation

## Example Output

```
[
  {
    "model": "llama2",
    "description": "A powerful language model for code and text completion."
  },
  {
    "model": "vicuna",
    "description": "An open, instruction-tuned model for dialogue."
  }
]
```

## Contributing

Pull requests, issues, and feature suggestions are welcome!

## License

Released under the MIT License.

---
