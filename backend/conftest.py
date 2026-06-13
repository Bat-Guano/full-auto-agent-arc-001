"""pytest configuration: isolate all backend tests from the dev database."""

import os
import tempfile

# Create one temp database for the entire test session.  pytest loads
# conftest.py before any test module is imported, so setting ITEMS_DB_PATH
# here guarantees that main.py (and therefore storage.py) will use this
# path for every test file.
_db_fd, _db_path = tempfile.mkstemp(suffix=".db", prefix="pytest_")
os.close(_db_fd)
os.unlink(_db_path)
os.environ["ITEMS_DB_PATH"] = _db_path
