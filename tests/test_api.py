import pytest
from unittest.mock import patch, Mock
from fastapi.testclient import TestClient
from ollama_library.main import (
    app,
)  # Adjust this import if your FastAPI app is elsewhere

client = TestClient(app)


def test_scrape_success(monkeypatch):
    # Mock response for requests.get inside the scraper
    from ollama_library.scraper.scraper import scrape_and_transform

    class MockResponse:
        status_code = 200
        text = """
        <div x-test-model-title="SampleModel" title="SampleModel">
            <p>This is a model description</p>
        </div>
        """

        def raise_for_status(self):
            pass

    def mock_get(url):
        return MockResponse()

    monkeypatch.setattr("requests.get", mock_get)

    response = client.get("/scrape?url=http://test.com")
    assert response.status_code == 200
    assert response.json()["models"][0]["name"] == "SampleModel"
    assert "description" in response.json()["models"][0]


def test_scrape_http_error(monkeypatch):
    # Simulate an HTTP error in requests.get
    from requests.exceptions import HTTPError

    class MockResponse:
        status_code = 404
        text = ""

        def raise_for_status(self):
            raise HTTPError(response=self)

    def mock_get(url):
        return MockResponse()

    monkeypatch.setattr("requests.get", mock_get)

    response = client.get("/scrape?url=http://doesnotexist.com")
    assert response.status_code == 404
    assert "HTTP error" in response.json()["detail"]


def test_scrape_parse_error():
    from ollama_library.scraper.scraper import scrape_and_transform
    from ollama_library.exceptions.scraper import ScraperParseError

    html = '<div x-test-model-title title="NoPTag"></div>'  # missing p tag
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.text = html
    mock_response.raise_for_status.return_value = None

    with patch("requests.get", return_value=mock_response):
        with pytest.raises(ScraperParseError):
            scrape_and_transform("http://fake.url")


def test_scrape_general_error(monkeypatch):
    # Simulate a network error
    def mock_get(url):
        raise Exception("Network down")

    monkeypatch.setattr("requests.get", mock_get)
    response = client.get("/scrape?url=http://anywhere.com")
    assert response.status_code == 500
    assert "Network" in response.json()["detail"]
