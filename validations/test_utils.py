"""
test_utils.py
--------------
Unit tests for source/utils/ modules: config_loader and validators.

Run with:
    pytest validations/test_utils.py -v
"""

import json
import sys
import pytest
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from source.utils.config_loader import load_config, get, ConfigError
from source.utils.validators import (
    ValidationError,
    require_file,
    require_directory,
    require_tool,
    require_args,
    ensure_directory,
)


# ── config_loader tests ───────────────────────────────────────────────────────

class TestLoadConfig:
    def _write_valid_config(self, path: Path) -> dict:
        config = {
            "project": {"name": "test"},
            "paths": {"data_root": "data"},
            "standard_files": {"brain": "brain10.nii.gz"},
            "resampling": {"output_size": "128x256x128"},
            "registration": {"dimension": 3},
            "groups": {"t1": {"label": "control"}},
            "logging": {"level": "INFO"},
        }
        path.write_text(json.dumps(config), encoding="utf-8")
        return config

    def test_loads_valid_config(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "config.json"
            self._write_valid_config(p)
            config = load_config(p)
            assert config["project"]["name"] == "test"

    def test_missing_file_raises_config_error(self):
        with pytest.raises(ConfigError):
            load_config("/nonexistent/config.json")

    def test_malformed_json_raises_config_error(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "config.json"
            p.write_text("{ bad json }", encoding="utf-8")
            with pytest.raises(ConfigError, match="Malformed JSON"):
                load_config(p)

    def test_missing_required_key_raises_config_error(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "config.json"
            p.write_text(json.dumps({"project": {}}), encoding="utf-8")
            with pytest.raises(ConfigError, match="missing required keys"):
                load_config(p)


class TestGet:
    def _make_config(self) -> dict:
        return {
            "registration": {"dimension": 3, "threads": 10},
            "logging": {"level": "DEBUG"},
        }

    def test_top_level_key(self):
        cfg = self._make_config()
        assert get("logging", config=cfg) == {"level": "DEBUG"}

    def test_nested_key(self):
        cfg = self._make_config()
        assert get("registration.dimension", config=cfg) == 3

    def test_missing_key_returns_default(self):
        cfg = self._make_config()
        assert get("nonexistent.key", config=cfg, default=42) == 42

    def test_missing_key_returns_none_by_default(self):
        cfg = self._make_config()
        assert get("no.such.path", config=cfg) is None


# ── validators tests ──────────────────────────────────────────────────────────

class TestRequireFile:
    def test_existing_file_returns_path(self):
        with tempfile.NamedTemporaryFile(suffix=".nii") as f:
            result = require_file(f.name)
            assert result == Path(f.name)

    def test_missing_file_raises(self):
        with pytest.raises(ValidationError):
            require_file("/nonexistent/brain.nii")


class TestRequireDirectory:
    def test_existing_dir_returns_path(self):
        with tempfile.TemporaryDirectory() as d:
            result = require_directory(d)
            assert result == Path(d)

    def test_missing_dir_raises(self):
        with pytest.raises(ValidationError):
            require_directory("/nonexistent/directory")


class TestRequireTool:
    def test_existing_tool(self):
        # "ls" should always be available
        result = require_tool("ls")
        assert result == "ls"

    def test_missing_tool_raises(self):
        with pytest.raises(ValidationError):
            require_tool("__nonexistent_tool_xyz__")


class TestRequireArgs:
    def test_correct_count_passes(self):
        require_args(["script.py", "a", "b"], expected=2, usage="")

    def test_too_few_exits(self):
        with pytest.raises(SystemExit):
            require_args(["script.py"], expected=2, usage="script.py a b")

    def test_too_many_exits(self):
        with pytest.raises(SystemExit):
            require_args(["script.py", "a", "b", "c"], expected=2, usage="")


class TestEnsureDirectory:
    def test_creates_nested_dir(self):
        with tempfile.TemporaryDirectory() as d:
            nested = Path(d) / "a" / "b" / "c"
            result = ensure_directory(nested)
            assert result.is_dir()
            assert result == nested

    def test_existing_dir_no_error(self):
        with tempfile.TemporaryDirectory() as d:
            result = ensure_directory(d)
            assert result.is_dir()
