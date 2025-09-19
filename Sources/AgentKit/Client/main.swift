import AgentKit

@Tool(
    name: "weather",
    description: "Get weather information for a city"
)
struct WeatherTool: ToolProtocol {
    /// Get weather information for a specific city
    /// - Parameter input: The city name to get the weather for
    func handler(input city: String) async throws -> String {
        "Weather for \(city): Sunny, 25°C"
    }
}

let agent = try await Agent(tools: [WeatherTool()])

/// Option 1. Just call the agent, it sends its ouput to stdout 
try await agent("What is the weather in Lille")

/// Option 2.  Provide the agent with a callback function
// try await agent("Tell me about swift 6") { event in
//     switch event {
//     case .text(let text):
//         print(text, terminator: "")
//     default:
//         break
//     }
// }

/// Option 3.  Invoke `streamAsync(String)` to receive a stream of events
// for try await event in agent.streamAsync("Tell me about swift 6") {
//     switch event {
//     case .text(let text):
//         print(text, terminator: "")
//     default:
//         break
//     }
// }
