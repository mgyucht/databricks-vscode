import os
import pytest

def test_env():
    assert os.getenv("FOO") == "bar"
