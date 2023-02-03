Performance Comparison of XMLTK and Xalan-c
===========================================

This repository contains a gold-standard reproduction package for "[Performance comparison of XMLTK and Xalan-c](https://doi.org/10.5281/zenodo.7604895)". It is a reproduction of the experiment performed by Iliana Avila-Campillo et. al. in 2002 as part of the paper "[XMLTK: An XML Toolkit for Scalable XML Stream Processing](https://www.cs.ucdavis.edu/~green/papers/planx02.pdf)", and compares the performane of [XMLTK](https://sourceforge.net/projects/xmltk/)'s `xsort` with that of [Xalan-c](https://apache.github.io/xalan-c/). This reproduction package was created as a student project for the lecture "Reproducibility Engineering" at the University of Passau.


Quick Start
-----------

To quickly build and run the experiment, use the following commands:

```sh
docker build -t repeng_xmltk .
mkdir output
docker run --rm -v "$(readlink -f output)":/output repeng_xmltk
```

This will produce a directory `output/` containing a full report as `report.pdf` and the raw results as CSV files.


Building the Container
----------------------

To build the container, simply run `docker build .`.

Cloning the XMLTK CVS repository from Sourceforge is currently unreliable.
Try re-running the build command in case you get an error message like the following:

```
cvs [checkout aborted]: unrecognized auth response from xmltk.cvs.sourceforge.net: cvs pserver: cannot read /cvsroot/xmltk/ CVSROOT/config: Operation not permitted
```


Running the Experiment
----------------------

Once you have built the container, you can run the full experiment using `docker run <image>`, where `<image>` it the ID or tag of the image you just built.

The final results, including a PDF report and the raw CSV data will be placed in `/output` inside the container. Use `docker run -v <directory>:/output` to automatically export those files into a directory on the host, or use `docker cp` to manually copy them.

Instead of running the whole experiment at once, you can start the container interactively using `docker run -it <image> /bin/bash`, and then manually run the individual steps. The relevant scripts are located in the `scripts/` directory. `doall.sh` is the main script that is used by default and calls all other scripts in the right order.


License
-------

This project and all its dependencies are free open source software. XMLTK is distributed under the public domain. Xalan-c and Xerces-c are licensed under the Apache-2.0 license.

For simplicity, and to ensure license compatibility, this reproduction package is also distributed under the Apache-2.0 license.


---

Inner Workings
--------------

The Docker container performs four main steps, each of which has its own challenges:

### Compiling the Tools

All three components (xsort, Xalan and Xerces) need some adjustments in order to get them to compile in a modern environment. These are stored as series of git patches in the `patches` directory and applied at container build time.

We explicitly use gcc-9 instead of Debian's default gcc-10 because gcc-10 causes problems with XMLTK's use of `flex`, which we were unable to resolve otherwise.

### Preparing the Dataset

As the input dataset, we use a snapshot of the [DBLP database](https://dblp.uni-trier.de/). It is automatically downloaded at build time, but extracted and pre-processed by `scripts/prepare-datasets.sh` at runtime in order to keep the image relatively small.

During pre-processing, multiple copies with different target sizes. The XML file is truncated to a fixed number of bytes, and then truncated further by removing the last element in order to create a valid XML output. This sanitization step is done using `xml-twig-tools` instead of the XML tools under evaluation, in order to prevent potential bugs in any of them from affect the whole experiment.

Additionally, any HTML-escape sequences (like `&auml;`) are removed from the input dataset in order to mitigate two problems:
* Xalan interprets these sequences as (broken) XML references and refuses to parse any datasets containing them. (This could also be fixed by re-adding a `DOCTYPE` specification to the datasets after pre-processing and downloading the relevant `dblp.dtd` from the DBLP archive.)
* Xalan, unlike xsort, un-escapes these sequences before processing an XML file. This results in different sort orders for any elements whose sorting key starts with such a sequence. Neither Xalan not xsort can be configured to mimic the other's behaviour.

### Running the Experiment

`scripts/run-experiment.sh` performs two experiments with both tools and all datasets produced in the previous step. For each run, three results are measured:
* Whether the tool produced **valid output**. Instead of doing an exact comparison, we check if the output is valid XML and contains the same number of publications as the input dataset. This check if good enough for its main purpose, namely detecting when a tool ran out of memory or crashed for some other reason.
* The **total runtime** of the tool. The runtime is only recorded if the tool produced valid output.
* The tool's **exit code**. This is not relevant for the experiment itself, but proved valuable for debugging.

One thing to note here is that xsort will always crash due to a segmentation fault *after* producing complete and valid output. This seems to be caused by some weirdness in the destructor of the `StackItem` class, but our attempts to fix it have always significantly impacted the program's memory consumption. This crash is problematic because it causes xsort's output to be truncated if its output is buffered. As a workaround, we therefore patch xsort to flush its standard output before exiting.

## Generating the report

Since we only have a relatively low number of results, we store them as CSV files and use these during the LaTeX build process via pgdplots' `\addplot table` functionality. Since pgfplots renders points in the order in which they appear in the CSV file, `scripts/build-report.sh` sorts them by dataset size before building the report.
