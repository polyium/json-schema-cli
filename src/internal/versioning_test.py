import pytest
import logging

import internal.versioning

logger = logging.getLogger(__name__)

def test_versioning_instance():
    instance = internal.versioning.Version()

    logger.debug("Version: %s", instance)

    assert instance

def test_versioning_tuple():
    assert isinstance(internal.versioning.Version().tuple, tuple)

def test_versioning_string_dunder_method():
    assert len(str(internal.versioning.Version()).split(".")) == 3
