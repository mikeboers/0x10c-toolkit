
.PHONY: default build clean test

default: build

build:
	python setup.py build_ext --inplace

clean:
	- rm -rf build
	- find dcpu16 -name '*.c'  | xargs rm
	- find dcpu16 -name '*.so' | xargs rm

color: build
	run examples/color_chart.dasm16

test: build
	nosetests
