#!/bin/sh
set -eu

cd "${HOME}/report"
rm -rf results
mkdir results

# Copy result CSVs, but sort them by input size. This makes it easier to import
# them in the report later.
for file in ../results/*; do
  sort --field-separator=, --key=3 --numeric "../results/${file}" -o "results/${file##*/}"
done

latexmk -gg -pdf report.tex

mkdir -p /output
cp report.pdf /output/report.pdf
