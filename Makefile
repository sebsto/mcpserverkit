
build:
	swift build
test:
	swift test
clean:
	swift package clean
	rm -rf .build
format:
	swift format format --parallel --recursive --in-place ./Package.swift Examples/ Sources/ Tests/

