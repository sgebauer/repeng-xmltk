#!/bin/sh
set -eu

cd "${HOME}/scripts"

echo "Preparing datasets"
./prepare-datasets.sh

echo "Running experiments"
./run-experiment.sh
