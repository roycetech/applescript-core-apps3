# Makefile.core.mk
# @Created: Tue, Jul 16, 2024 at 11:43:13 AM
# @Purpose:
# 	Contains the core libraries.

ifeq ($(USE_SUDO),true)
	SUDO := sudo
	SCRIPT_LIBRARY_PATH := /Library/Script Libraries
else
	SUDO :=
	SCRIPT_LIBRARY_PATH := $(HOME)/Library/Script Libraries
endif


APPS_PATH=/Applications/AppleScript

check:
	@if [ ! -d "$(SCRIPT_LIBRARY_PATH)/core" ]; then \
		echo "AppleScript Core installation was not found."; \
		exit 1; \
	else \
		echo "✅ AppleScript Core installation was found."; \
	fi


init: check

ifeq ($(DEPLOY_TYPE), user)
	@if [ ! -d "~/Applications/AppleScript/Stay\ Open/" ]; then \
		mkdir -p ~/Applications/AppleScript/Stay\ Open/; \
	fi
else
	@if [ ! -d "/Applications/AppleScript/Stay\ Open/" ]; then \
		$(SUDO) mkdir -p /Applications/AppleScript/Stay\ Open/; \
	fi
endif


clean:
	find . -name '*.scpt' ! -name "main.scpt" -delete

install: _init build
ifeq ($(DEPLOY_TYPE), user)
	mkdir -p ~/Library/'Script Libraries'/core/test
	mkdir -p ~/Library/'Script Libraries'/core/app
else
	$(SUDO) mkdir -p /Library/'Script Libraries'/core/test
	$(SUDO) mkdir -p /Library/'Script Libraries'/core/app
endif
	touch ~/applescript-core/logs/applescript-core.log
#	osascript scripts/setup-applescript-core-project-path.applescript
# 	./scripts/setup-switches.sh
	@echo "applescript-core installation completed\n"


build-extras: \
	build-redis \


build-all: \
	build \
	build-extras

install-all: build-all


reveal-scripts:  # Reveal the deployed scripts.
	open "$(SCRIPT_LIBRARY_PATH)/core"


# Helper function to build and confirm with yes to the prompt.
_build-script = \
	@echo "Building $(1)"; \
	yes y | ./scripts/build-lib.sh $(1)


# Directory containing the decorator scripts
DECORATORS_PATH = ./decorators
DECORATORS = $(wildcard $(DECORATORS_PATH)/dec-*.applescript)

build-decorators: init
	@echo "Building app decorators..."
	@for file in $(DECORATORS); do \
		no_ext=$${file%.applescript}; \
		echo "Building $$file"; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Done building core decorators\n"


# Deprecated targets ----------------------------------------------------------

build-lib:  # Deprecated on 20260219. Use the ./scripts/build-lib.sh directly.
	$(SUDO) ./scripts/build-lib.sh $(SOURCE)

build-bundle:  # Deprecated on 20260219. Use the ./scripts/build-bundle.sh directly.
	$(SUDO) ./scripts/build-bundle.sh $(SOURCE)
