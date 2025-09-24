from fastapi import APIRouter, Query, HTTPException
from ollama_library.scraper.scraper import scrape_and_transform
from ollama_library.exceptions.scraper import (
    ScraperHTTPError,
    ScraperParseError,
    ScraperError,
)
from ollama_library.models.schemas import ScrapedData, ModelData

router = APIRouter()


@router.get("/scrape", response_model=ScrapedData)
def get_scraped_data(url: str = Query(..., description="The URL to scrape")):
    try:
        data = scrape_and_transform(url)
        models = [ModelData(**item) for item in data]
        return ScrapedData(models=models)
    except ScraperHTTPError as err:
        raise HTTPException(status_code=err.status_code, detail=str(err))
    except ScraperParseError as err:
        raise HTTPException(status_code=500, detail=str(err))
    except ScraperError as err:
        raise HTTPException(status_code=500, detail=str(err))
