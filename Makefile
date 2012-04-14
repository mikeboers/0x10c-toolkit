
.PHONY: default build clean test

default: build

build:
	python setup.py build_ext --inplace

clean:
	rm -rf build
	rm dcpu16/*.{c,so}

color: build
	run examples/color_chart.dasm16

test: build
	nosetests
