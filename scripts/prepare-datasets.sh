#!/bin/sh
set -eu

cd "${HOME}/datasets"

gunzip dblp.xml.gz

# This function creates a truncated and sanitized copy of dblp.xml with
# approximately the given length in bytes.
prepare_file() {
  size="$1"
  file="dblp-${size}.xml"

  echo "Generating $file ..."

  # Read dblp.xml and truncate it to the given size. The output will be invalid XML.
  head -c "$size" dblp.xml | \
    # Sanitize the output with xml_grep. It will discard the last (incomplete)
    # child entry of <dblp> and add the missing </dblp> close tag at the end.
    xml_grep --wrap dblp --descr '' --pretty_print indented '/dblp/*' /dev/fd/0 | \
    # Replace HTML-escaped characters like "&auml;" with a dummy character.
    # Otherwise, Xalan (unlike xsort) will un-escape these during the
    # experiment, causing different sort orders between Xalan and xsort.
    # Write the output to the target file and discard all errors (xml_grep will
    # always complain about its invalid input).
    sed 's/&[a-zA-Z]\+;/_/g' >"$file" 2>/dev/null || true
}

# These are the input sizes used in the original paper, rounded up to the
# nearest full KB (except for the first, which is rounded to 100B). This is
# because the output will be slightly shorter than the target size.
prepare_file 500
prepare_file 5000
prepare_file 77000
prepare_file 992000
prepare_file 9672000
prepare_file 100965000
prepare_file 1009644000

rm dblp.xml

# To make sure everything worked as expected (also because be ignore all
# xml_grep errors above), compare SHA1 checksums of the final output. If they
# don't match, sha1sums will exit with a non-zero exit code and cause the build
# process to abort.
sha1sum -c "datasets.sha1sums"
