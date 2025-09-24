from fastapi import FastAPI
from ollama_library.api.endpoints import router

app = FastAPI()
app.include_router(router)
