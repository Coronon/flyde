[![codecov](https://codecov.io/gh/Coronon/flyde/branch/master/graph/badge.svg?token=MG4AR31KY2)](https://codecov.io/gh/Coronon/flyde)

# flyde

_flyde_ is a command line tool, which boosts the productivity of C++ developers greatly.
You are able to define compiler routines, workflows and even custom Python scripts to meet the requirements of modern and complex solutions.
_flyde_ allows you to focus on your main tasks instead of fighting with the compiler and creating build / test / deploy / ... scripts.
Simply define what you want once and let _flyde_ do the boring work.

## Features (WiP)

- Write your compiler requirements in a configuration file and _flyde_ takes care of invocing g++, placing your binary and much more
- Define workflows! A workflow could consist of compiling your code with a specific config and then run it to f.E. execute unit tests
- Faster build speed thanks to advanced caching and multi-threading support

## Installation

To install the project the Dart SDK is required.

```sh
pub get
```

## Running

```sh
dart run
```
