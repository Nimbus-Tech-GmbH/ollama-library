class ScraperError(Exception):
    """Base exception class for scraper errors."""

    pass


class ScraperHTTPError(ScraperError):
    """Exception for HTTP errors encountered by the scraper."""

    def __init__(self, status_code, message):
        self.status_code = status_code
        super().__init__(message)


class ScraperParseError(ScraperError):
    """Exception for parsing errors during scraping."""

    pass
