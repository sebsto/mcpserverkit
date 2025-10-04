import MCPServerKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

//
// EXAMPLE WITHOUT MACROS
//

@main
struct Test {
    static func main() async throws {

        // Create the server with multiple tools of different types
        let server = MCPServer.create(
            name: "MultiToolServer",
            version: "1.0.0",
            tools: [
                WeatherTool(),  // String input, String output
                CalculatorTool(),  // CalculatorInput input, Double output
                FXRateTool(),  // FXRatesInput input, String output
            ],
            prompts: [myWeatherPrompt, fxRatesPrompt],
        )

        // Start the server
        try await server.startStdioServer()
    }
}

//
// EXAMPLE WITH MACROS
//
// @Server(
//     name: "MultiToolServer",
//     version: "1.0.0",
//     description: "A server that provides multiple tools",
//     tools: [
//         WeatherTool(),  // String input, String output
//         CalculatorTool(),  // CalculatorInput input, Double output
//         FXRateTool(),  // FXRatesInput input, String output
//     ],
//     prompts: [myWeatherPrompt, fxRatesPrompt],
//     type: .stdio
// )
// @main
// struct MultiToolServer {}

//
// EXAMPLE CALLING A TOOL WITHOUT SERVER (just for debugging)
//

// @main
// struct Test {
//     static func main() async throws {
//         let fxr = FXRateTool()
//         print("FXRatesTool loaded")
//         print(fxr.name)
//         print(fxr.description)
//         print(fxr.inputSchema)

//         let input = FXRatesInput(
//             sourceCurrency: "USD",
//             targetCurrency: "EUR",
//         )
//         let result = try await fxr.handle(input: input)
//         print(result)

//         print("----------")
//         let wt = WeatherTool()
//         print("WetherTool loaded")
//         print(wt.name)
//         print(wt.description)
//         print(wt.inputSchema)
//         let weather = try await wt.handle(input: "Brussels")
//         print(weather.prefix(100))

//     }
// }
