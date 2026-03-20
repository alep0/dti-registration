"""
conftest.py
-----------
Pytest configuration: add project root to sys.path so that
``source.*`` imports work without installation.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
