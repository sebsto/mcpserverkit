import MCPServerKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Create the server with multiple tools of different types
let server = MCPServer.create(
    name: "MultiToolServer",
    version: "1.0.0",
    tools: [
        myWeatherTool,  // String input, String output
        calculatorTool,  // CalculatorInput input, Double output
        FXRateTool(),    // FXRatesInput input, String output
    ],
    prompts: [myWeatherPrompt, fxRatesPrompt],
)

// Start the server
try await server.startStdioServer()

// let fxr = FXRateTool()
// print("FXRatesTool loaded")
// print(fxr.name)
// print(fxr.description)
// print(fxr.inputSchema)

// let input = FXRatesInput(
//     sourceCurrency: "USD",
//     targetCurrency: "EUR",
// )
// let result = try await fxr.handler(input: input) 
// print(result)

// print("----------")
// print("WetherTool loaded")
// print(myWeatherTool.name)
// print(myWeatherTool.description)
// print(myWeatherTool.inputSchema)    
// let weather = try await myWeatherTool.handler(input: "Brussels")
// print(weather.prefix(100))