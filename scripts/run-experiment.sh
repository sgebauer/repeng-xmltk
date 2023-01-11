#!/bin/sh
set -eu

readonly DATASET_DIR="${HOME}/datasets"
readonly DATASET_FILES="$(find "$DATASET_DIR" -name '*.xml')"
readonly TEMPLATES_DIR="${HOME}/xslt-templates"
readonly MEMORY_LIMIT=$(( (128 + 512) * 1024 * 1024 ))
readonly BUFFER_FILE="${HOME}/buffer"

# Execute the given command, measure its runtime in milliseconds and write it
# to the results CSV.
validate_and_measure() {
  experiment_name="$1"
  tool_name="$2"
  input_file="$3"
  shift 3

  echo "Running experiment '${experiment_name}' with tool '${tool_name}' and input '${input_file}': $*"

  set +e
  before="$(date '+%s%N')"
  prlimit --as="${MEMORY_LIMIT}:${MEMORY_LIMIT}" "$@" >"$BUFFER_FILE"
  exitcode=$?
  after="$(date '+%s%N')"
  set -e

  runtime="$(( (after - before) / 1000000 ))"
  size="$(wc --bytes "$input_file")"
  original_count="$(xml_grep --count '/dblp/*' "$input_file" | awk '/^total:/{ print $2 }')"
  sorted_count="$(xml_grep --count '/dblp/*' "$BUFFER_FILE" | awk '/^total:/{ print $2 }')"

  if [ "$original_count" -eq "$sorted_count" ]; then
    echo "${experiment_name},${tool_name},${size},1" | tee --append "${HOME}/results/valid_output.csv"
    echo "${experiment_name},${tool_name},${size},${runtime}" | tee --append "${HOME}/results/runtime.csv"
  else
    # If the tool did not produce valid output, the runtime is likely useless
    # because the tool crashed before it could finish.
    echo "${experiment_name},${tool_name},${size},0" | tee --append "${HOME}/results/valid_output.csv"
  fi
  echo "${experiment_name},${tool_name},${size},${exitcode}" | tee --append "${HOME}/results/exitcode.csv"
}

mkdir -p "${HOME}/results"
echo "Experiment,Tool,Dataset Size,Runtime" >"${HOME}/results/runtime.csv"
echo "Experiment,Tool,Dataset Size,Valid" >"${HOME}/results/valid_output.csv"
echo "Experiment,Tool,Dataset Size,Exit Code" >"${HOME}/results/exitcode.csv"

for file in $DATASET_FILES; do
  # Read the whole file first in order to load it into the disk cache.
  # Otherwise, the first experiment run might have a speed disadvantage due to
  # disk read speed.
  cat "$file" >/dev/null

  validate_and_measure global-sort xsort "$file"  xsort -c '/dblp' -e '*' -k 'title/text()' "$file"
  validate_and_measure global-sort xalan "$file"  Xalan "$file" "${TEMPLATES_DIR}/a-global-sort.xslt"
done
