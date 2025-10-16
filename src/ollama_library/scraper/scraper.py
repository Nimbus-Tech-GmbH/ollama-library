import requests
from bs4 import BeautifulSoup
from ollama_library.exceptions.scraper import (
    ScraperError,
    ScraperHTTPError,
    ScraperParseError,
)


def scrape_and_transform(url: str) -> list[dict[str, str]]:
    try:
        response = requests.get(url)
        response.raise_for_status()
    except requests.exceptions.ConnectionError as conn_err:
        # Domain is not found or unreachable
        raise ScraperError(f"Domain not found or unreachable: {conn_err}") from conn_err
    except requests.exceptions.InvalidURL as invalid_url_err:
        # URL is malformed or domain does not exist
        raise ScraperError(
            f"Invalid URL or domain not found: {invalid_url_err}"
        ) from invalid_url_err
    except requests.exceptions.HTTPError as http_err:
        status = http_err.response.status_code if http_err.response else 500
        raise ScraperHTTPError(status, f"HTTP error: {http_err}") from http_err
    except Exception as err:
        raise ScraperError(f"Network or unknown error: {err}") from err

    try:
        soup = BeautifulSoup(response.text, "html.parser")
        names = []
        descriptions = []
        divs = soup.find_all("div", attrs={"x-test-model-title": True})
        for div in divs:
            names.append(div.get("title"))
            descriptions.append(div.find("p").get_text(strip=True))
        results = []
        for name, description in zip(names, descriptions):
            results.append({"name": name, "description": description})
        return results
    except Exception as parse_err:
        raise ScraperParseError(f"Failed to parse content: {parse_err}") from parse_err
