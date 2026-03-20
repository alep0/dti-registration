"""
logger.py
---------
Centralised logging factory for the DTI-registration pipeline.

All modules import `get_logger(__name__)` to obtain a logger that writes
simultaneously to the console and to a timestamped file under the logs/
directory defined in config.json.
"""

import logging
import os
import sys
import json
from datetime import datetime
from pathlib import Path

_CONFIG_PATH = Path(__file__).resolve().parents[2] / "config" / "config.json"

def _load_log_config() -> dict:
    """Load logging settings from config.json, fall back to safe defaults."""
    try:
        with open(_CONFIG_PATH, "r", encoding="utf-8") as fh:
            return json.load(fh).get("logging", {})
    except Exception:
        return {}


def get_logger(name: str, logs_dir: str | None = None) -> logging.Logger:
    """
    Return a named logger that writes to console + a timestamped log file.

    Parameters
    ----------
    name : str
        Logger name – typically ``__name__`` of the calling module.
    logs_dir : str | None
        Override for the log output directory.  When *None* the value from
        config.json is used (``logs/``), resolved relative to the project root.

    Returns
    -------
    logging.Logger
    """
    cfg = _load_log_config()
    level_name: str = cfg.get("level", "INFO")
    fmt: str = cfg.get("format", "%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    date_fmt: str = cfg.get("date_format", "%Y-%m-%d %H:%M:%S")

    # Resolve logs directory
    if logs_dir is None:
        project_root = Path(__file__).resolve().parents[2]
        logs_dir = project_root / "logs"
    logs_path = Path(logs_dir)
    logs_path.mkdir(parents=True, exist_ok=True)

    # Timestamped log file named after the calling script
    script_stem = Path(sys.argv[0]).stem if sys.argv[0] else "pipeline"
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = logs_path / f"{script_stem}_{timestamp}.log"

    logger = logging.getLogger(name)
    if logger.handlers:
        # Already configured – return as-is to avoid duplicate handlers
        return logger

    logger.setLevel(getattr(logging, level_name.upper(), logging.INFO))
    formatter = logging.Formatter(fmt, datefmt=date_fmt)

    # File handler
    fh = logging.FileHandler(log_file, encoding="utf-8")
    fh.setFormatter(formatter)
    logger.addHandler(fh)

    # Console handler
    ch = logging.StreamHandler(sys.stdout)
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    return logger
