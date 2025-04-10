import MCP
import MCPServerKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// This tool returns current weather and weather forecast for a given city.

// FIXME: we need a way to generate this from the actual handler type :-)
let myWeatherToolSchema =
    """
    {
        "type": "object",
        "properties": {
          "city": {
            "description": "The city name to get the weather for",
            "type": "string"
          }
        },
        "required": [
          "city"
        ]
      }
    """

let myWeatherToolDescription =
    "This tool returns current weather and weather forecast for a given city. It returns current data and forecasted data, such as temperature in celsius and farenheit, humidity, rain level in milimiters and inches, wind speed in kmh and mph and direction, pressure in milibar and inches, visibility, weather description."

let myWeatherTool = MCPTool<String, String>(
    name: "weather",
    description: myWeatherToolDescription,
    inputSchema: myWeatherToolSchema,
    converter: { params in
        return try MCPTool<String, String>.extractParameter(params, name: "city")
    },
    body: { (input: String) async throws -> String in
        let weatherURL = "http://wttr.in/\(input)?format=j1"
        let url = URL(string: weatherURL)
        guard let url else {
            throw MCPServerError.invalidParam("city", "\(input)")
        }
        let (data, _) = try await URLSession.shared.data(from: url)

        // return the data as a string
        return String(decoding: data, as: UTF8.self)
    }
)

let myWeatherPrompt = try! MCPPrompt.build { builder in
            builder.name = "current-weather"
            builder.description = "A prompt asking the current weather for a given city"
            builder.text("What is the weather today in {city}?")
            builder.parameter("city", description: "the name of the city to get the weather for")
}
