list:
	cat list_tools.json | swift run
weather:
	cat call_weather_tool.json | swift run
calculator:
	cat call_calculator_tool.json | swift run
build:
	swift build
test:
	swift test
clean:
	swift package clean
	rm -rf .build
