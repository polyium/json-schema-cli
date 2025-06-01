"""
An example entrypoint.
"""

import sys
import re
import typing

import logging
import argparse

handler = logging.StreamHandler()

logger = logging.getLogger(__name__)


class Formatter(logging.Formatter):
    expression = r"(?<!\w)'([^\s']+)'(?!\w)"
    substitution = r'"\1"'

    def format(self, record) -> str:
        # Modify the record or format the message as needed.
        v = super().format(record)  # .replace("'", "%s" % '"')

        return re.sub(self.expression, self.substitution, v)

formatter = Formatter("[%(levelname)s] (%(asctime)s) (%(name)s) %(message)s")

handler.setFormatter(formatter)

def version():
    import polyium.internal.versioning

    v = polyium.internal.versioning.Version()

    sys.stdout.write("%s\n" % v)

    exit(0)

def executable():
    logging.basicConfig(level=logging.DEBUG, datefmt="%Y-%m-%dT%H:%M:%SZ")
    logger.addHandler(handler)
    logger.propagate = False

    # Create an argument parser object.
    parser = argparse.ArgumentParser(description="Python Example Template")

    parser.add_argument("-v", "--version", action="store_true", help="display the version", dest="version")

    parser_group_1 = parser.add_argument_group("logging")
    parser_group_1.add_argument("--verbose", type=bool, help="toggle verbose output", metavar="")
    parser_group_1.add_argument("--log-level", type=str, choices=["DEBUG", "INFO", "ERROR"], metavar="LEVEL", help="the global logging level to display", required=False, default="INFO")

    # Parse arguments.
    namespace = parser.parse_args()

    arguments = vars(namespace)

    if arguments["version"]:
        version()

    logger.debug("Arguments: %r", arguments)

if __name__ == "__main__":
    executable()
