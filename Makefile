list-tools:
	cat json/list_tools.json | swift run
call-weather:
	cat json/call_weather_tool.json | swift run
call-calculator:
	cat json/call_calculator_tool.json | swift run
list-prompts:
	cat json/list_prompts.json | swift run
get-prompt:
	cat json/get_prompt.json | swift run
build:
	swift build
test:
	swift test
clean:
	swift package clean
	rm -rf .build

