list-tools:
	cat json/list_tools.json | swift run MCPExample
call-weather:
	cat json/call_weather_tool.json | swift run MCPExample
call-calculator:
	cat json/call_calculator_tool.json | swift run MCPExample
call-fxrate:
	cat json/call_fxrate_tool.json | swift run MCPExample
list-prompts:
	cat json/list_prompts.json | swift run MCPExample
get-prompt:
	cat json/get_prompts.json | swift run MCPExample
build:
	swift build
test:
	swift test
clean:
	swift package clean
	rm -rf .build

