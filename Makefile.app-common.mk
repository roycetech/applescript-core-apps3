# Makefile.app-common.mk
# @Created: Mon, Mar 09, 2026, at 08:47:53 AM
# @Description:
# 	Contains the common app scripts for 1st and 3rd party apps.

build-base-app:
	@echo "\nBuilding Base App scripts..."
	$(call _build-script,apps/base-app)
	$(call _build-script,apps/abstract-app-with-file-dialog)
	@echo "Build Base App scripts completed\n"


_build-versioned-directory = \
	@echo "Building $(1) version $(3) compatible scripts..."; \
	find "$(2)" -maxdepth 1 -type d -name '[0-9]*.[0-9]*' -print0 | sort -zV | \
	while IFS= read -r -d '' d; do \
		dirver=$$(basename "$$d"); \
		awkver=$$(awk 'BEGIN {if ("'$$dirver'" <= "'$(3)'") print 1; else print 0}'); \
		if [ "$$awkver" -eq 1 ]; then \
			echo "  Compiling AppleScripts in \"$$d\"..."; \
			find "$$d" -maxdepth 1 -type f -name '*.applescript' -print0 | \
			while IFS= read -r -d '' file; do \
				no_ext=$${file%.applescript}; \
				echo "    Building \"$$no_ext\""; \
				yes y | ./scripts/build-lib.sh "$$no_ext"; \
			done; \
		else \
			echo "  Skipping directory \"$$d\" (version \"$$dirver\" is greater than $(3))"; \
		fi \
	done; \
	echo "Done building $(1) up to version $(3)"


# @1 - App name
# @2 - folder to build the scripts from
_build-app-scripts = \
	@echo "Building $(1) scripts..."; \
	find "$(2)" -maxdepth 1 -type f -name '*.applescript' -print0 \
	| while IFS= read -r -d '' file; do \
		echo "Building $$file"; \
		no_ext=$${file%.applescript}; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done; \
	echo "Build $(1) scripts completed\n";


# $1 - Title
# $2 - Folder path
_build-directory = \
	@echo "Building $(1) scripts..."; \
	find "$(2)" -maxdepth 1 -type f -name '*.applescript' -print0 | sort -z \
	| while IFS= read -r -d '' file; do \
		no_ext=$${file%.applescript}; \
		echo "Building $$file ($$no_ext)"; \
	done; \
	echo "Done building $(1) scripts\n"
