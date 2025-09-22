import AgentKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Tool(
    name: "weather",
    description: "Get weather information for a city"
)
struct WeatherTool: ToolProtocol {
    /// Get weather information for a specific city
    /// - Parameter input: The city name to get the weather for
    func handle(input city: String) async throws -> String {
        let weatherURL = "http://wttr.in/\(city)?format=j1"
        let url = URL(string: weatherURL)!
        let (data, _) = try await URLSession.shared.data(from: url)

        // return the data as a string
        return String(decoding: data, as: UTF8.self)
    }
}

let agent = try await Agent(tools: [WeatherTool()])

/// Option 1. Just call the agent, it sends its ouput to stdout 
try await agent("What is the weather in Lille today? Give a one paragraph summary with key metrics. Do not use bullet points.")

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
