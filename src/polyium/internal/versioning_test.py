import pytest
import logging

import polyium.internal.versioning

logger = logging.getLogger(__name__)

def test_versioning_instance():
    instance = polyium.internal.versioning.Version()

    logger.debug("Version: %s", instance)

    assert instance

def test_versioning_tuple():
    assert isinstance(polyium.internal.versioning.Version().tuple, tuple)

def test_versioning_string_dunder_method():
    assert len(str(polyium.internal.versioning.Version()).split(".")) == 3
