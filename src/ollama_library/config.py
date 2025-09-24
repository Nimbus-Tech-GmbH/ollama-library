import os
from dotenv import load_dotenv

_ = load_dotenv()

SCRAPER_TIMEOUT = int(os.getenv("SCRAPER_TIMEOUT", "10"))
