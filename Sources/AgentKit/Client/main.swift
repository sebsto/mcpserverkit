import AgentKit

let agent = try await Agent(tools: [WeatherTool(), FXRateTool()])

/// Option 1. Just call the agent, it sends its ouput to stdout 
// try await agent("What is the weather in Lille today? Give a one paragraph summary with key metrics. Do not use bullet points.")
try await agent("How much is 100 GBP in EUR?")

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
