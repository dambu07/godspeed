.PHONY: help install test lint build release deploy clean

help:
	@echo "Godspeed Development Commands:"
	@echo ""
	@echo "  make install    - Install Godspeed locally"
	@echo "  make test       - Run all tests"
	@echo "  make lint       - Run linting"
	@echo "  make build      - Build distribution packages"
	@echo "  make release    - Create new release"
	@echo "  make deploy     - Deploy to repositories"
	@echo "  make clean      - Clean build artifacts"
	@echo ""

install:
	@echo "Installing Godspeed for development..."
	chmod +x godspeed.sh
	sudo ln -sf $(PWD)/godspeed.sh /usr/local/bin/godspeed
	@echo "✅ Godspeed installed. Run 'godspeed --help' to test."

test:
	@echo "Running Godspeed tests..."
	./test/run-tests.sh

lint:
	@echo "Linting shell scripts..."
	shellcheck godspeed.sh scripts/*.sh install/*.sh

build:
	@echo "Building distribution packages..."
	./scripts/setup-repo.sh

release:
	@echo "Creating release..."
	@read -p "Enter version (e.g., 0.8.0): " version; \
	./scripts/release.sh $$version

deploy:
	@echo "Deploying to repositories..."
	./scripts/deploy.sh

clean:
	@echo "Cleaning build artifacts..."
	rm -rf dist/
	rm -rf packages/debian/*.deb
	rm -rf packages/rpm/BUILD packages/rpm/RPMS packages/rpm/SRPMS
	rm -f *.bak *.tmp
	@echo "✅ Clean complete"

dev-setup:
	@echo "Setting up development environment..."
	mkdir -p ~/.godspeed/{logs,api_keys,ports,plugins}
	npm install
	chmod +x scripts/*.sh install/*.sh test/*.sh
	@echo "✅ Development setup complete"
