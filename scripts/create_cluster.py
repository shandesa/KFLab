import argparse
import os
import datetime
import logging
import subprocess
import time
import sys
#from termcolor import colored

import random
from random import randint

from kubernetes import client, config
import util

if __name__ == "__main__":
  logging.basicConfig(level=logging.INFO,
                      format=('%(levelname)s|%(asctime)s'
                              '|%(pathname)s|%(lineno)d| %(message)s'),
                      datefmt='%Y-%m-%dT%H:%M:%S',
                      )
  logging.getLogger().setLevel(logging.INFO)
  # create the top-level parser
  parser = argparse.ArgumentParser(
    description="Submit test to run the nightly .")

  parser.add_argument(
    "--project",
    default="cpsg-ai-test",
    type=str,
    help="The project containing the GKE cluster.")

  parser.add_argument(
    "--zone",
    default="asia-south1-a",
    type=str,
    help="The zone to create the GKE cluster.")

  parser.add_argument(
    "--name",
    default="kubebench",
    type=str,
    help="The zone to create the GKE cluster.")

  parser.add_argument(
    "--logpath",
    default="nightly_logs",
    type=str,
    help="The app to run <mnist>/<>")

  # Parse the args
  args = parser.parse_args()

  # Setup a logging file handler. This way we can upload the log outputs
  # to gubernator.
  root_logger = logging.getLogger()

  test_log = os.path.join(args.logpath, args.name+"-cluster-create.log")
  if not os.path.exists(os.path.dirname(test_log)):
    try:
      os.makedirs(os.path.dirname(test_log))
    # Ignore OSError because sometimes another process
    # running in parallel creates this directory at the same time
    except OSError:
      pass


  file_handler = logging.FileHandler(test_log)
  root_logger.addHandler(file_handler)
  # We need to explicitly set the formatter because it will not pick up
  # the BasicConfig.
  formatter = logging.Formatter(fmt=("%(levelname)s|%(asctime)s"
                                     "|%(pathname)s|%(lineno)d| %(message)s"),
                                datefmt="%Y-%m-%dT%H:%M:%S")
  file_handler.setFormatter(formatter)
  logging.info("Logging to %s", test_log)

  util.create_gcloud_cluster(args.project, args.zone, args.name)
  util.get_cluster_info()
  logging.info(args)
  #repo_dir = clone_repo("nightly_repo")
  sys.exit(0)
