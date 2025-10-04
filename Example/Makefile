list-tools:
	@cat json/list_tools.json | swift run MCPExampleServer 2>/dev/null
call-weather:
	@cat json/call_weather_tool.json | swift run MCPExampleServer 2>/dev/null
call-calculator:
	@cat json/call_calculator_tool.json | swift run MCPExampleServer 2>/dev/null
call-fxrate:
	@cat json/call_fxrate_tool.json | swift run MCPExampleServer 2>/dev/null
list-prompts:
	@cat json/list_prompts.json | swift run MCPExampleServer 2>/dev/null
get-prompt:
	@cat json/get_prompts.json | swift run MCPExampleServer 2>/dev/null
build:
	swift build
test:
	swift test
clean:
	swift package clean
	rm -rf .build
format:
	swift format format --parallel --recursive --in-place ./Package.swift Examples/ Sources/ Tests/

