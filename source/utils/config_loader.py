"""
config_loader.py
----------------
Utility for loading and validating the project configuration (config.json).
"""

import json
from pathlib import Path
from typing import Any

_DEFAULT_CONFIG_PATH = Path(__file__).resolve().parents[2] / "config" / "config.json"


class ConfigError(Exception):
    """Raised when the configuration file is missing or malformed."""


def load_config(config_path: Path | str | None = None) -> dict[str, Any]:
    """
    Load and return the project configuration dictionary.

    Parameters
    ----------
    config_path : Path | str | None
        Path to ``config.json``.  Defaults to ``config/config.json`` in the
        project root.

    Returns
    -------
    dict[str, Any]

    Raises
    ------
    ConfigError
        If the file is not found or cannot be parsed.
    """
    path = Path(config_path) if config_path else _DEFAULT_CONFIG_PATH
    if not path.exists():
        raise ConfigError(f"Configuration file not found: {path}")
    try:
        with open(path, "r", encoding="utf-8") as fh:
            config = json.load(fh)
    except json.JSONDecodeError as exc:
        raise ConfigError(f"Malformed JSON in {path}: {exc}") from exc

    _validate_config(config)
    return config


def _validate_config(config: dict) -> None:
    """Raise ConfigError if required top-level keys are absent."""
    required_keys = ["project", "paths", "standard_files", "resampling",
                     "registration", "groups", "logging"]
    missing = [k for k in required_keys if k not in config]
    if missing:
        raise ConfigError(f"Configuration is missing required keys: {missing}")


def get(key_path: str, config: dict | None = None, default: Any = None) -> Any:
    """
    Retrieve a nested config value using dot-notation.

    Example
    -------
    >>> get("registration.dimension")
    3

    Parameters
    ----------
    key_path : str
        Dot-separated path, e.g. ``"registration.dimension"``.
    config : dict | None
        Pre-loaded config dict.  Loaded from disk when *None*.
    default : Any
        Value returned when the key path does not exist.
    """
    cfg = config if config is not None else load_config()
    keys = key_path.split(".")
    node = cfg
    for key in keys:
        if not isinstance(node, dict) or key not in node:
            return default
        node = node[key]
    return node
