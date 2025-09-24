from pydantic import BaseModel


class ModelData(BaseModel):
    name: str
    description: str


class ScrapedData(BaseModel):
    models: list[ModelData]
