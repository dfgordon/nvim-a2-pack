# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] - 2024-12-08

### Fixes

* Handle spaces in path completions

## [0.3.0] - 2024-11-17

### New Features

* Convert data to code (requires `a2kit` version 3.4.0 or higher)

## [0.2.0] - 2024-10-19

### New Features

* Disk image support
    - load BASIC programs or Merlin source files
    - save BASIC programs or Merlin source files
    - load binary files as disassembly
* Disassembly
    - spot assembler to generate data sections

## [0.1.2] - 2024-10-06

### Fixes

* Fallback to working directory if `.git` not found

## [0.1.1] - 2024-10-06

### Fixes

* Handle non-default load-addresses correctly

## [0.1.0] - 2024-10-06

### New Features

* Add LSP command processor
    - Renumber Applesoft or Integer
    - Tokenize Applesoft or Integer
    - Minify Applesoft
