# roblox-modular — build & verification pipeline
#
# Targets:
#   make extract   — split input/message(47).txt into src/, assets/ (+ manifest)
#   make bundle    — build dist/main.lua (self-contained executor script)
#   make verify    — run every integrity / syntax / bundle / smoke / zip check
#   make zip       — package dist/roblox-modular.zip (INCLUDE_INPUT=1 embeds input/)
#   make smoke     — run only the lune runtime smoke test
#   make all       — extract + bundle + verify + zip
#   make clean     — remove generated artifacts (keeps src/, assets/, scripts/)

PYTHON  ?= python3

# Optional: directory containing luau, luau-analyze, stylua, selene, lune.
# Makefile adds it to PATH automatically if it exists next to the project.
TOOLS_DIR ?= $(abspath ../tools)
ifneq ($(wildcard $(TOOLS_DIR)/.),)
export PATH := $(TOOLS_DIR):$(PATH)
endif

.PHONY: all extract bundle verify zip smoke clean help

.DEFAULT_GOAL := all

all: extract bundle verify zip

extract:
	$(PYTHON) scripts/extract.py

bundle: extract
	$(PYTHON) scripts/bundle.py

verify: extract
	$(PYTHON) scripts/verify.py

zip:
	$(PYTHON) scripts/build_zip.py $(if $(filter 1,$(INCLUDE_INPUT)),--include-input,)

smoke:
	$(PYTHON) scripts/verify.py --only smoke

clean:
	rm -rf dist/main.lua dist/bundle_report.json dist/roblox-modular.zip
	rm -rf scripts/.smoke scripts/__pycache__
	@echo "cleaned (extract_manifest.json kept; run 'make extract' to regenerate everything)"

help:
	@sed -n '2,12p' $(firstword $(MAKEFILE_LIST))
