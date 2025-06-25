import Foundation
import ToolMacro
import MCPServerKit
import MCP

// Example 1: Simple string input with DocC-generated schema
@Tool(name: "weather", description: "Get weather information for a city")
struct WeatherTool: MCPToolProtocol {
    typealias Input = String
    typealias Output = String
    // var i = 0
    
    /// Get weather information for a specific city
    /// - Parameter input: The city name to get the weather for
    func handler(input city: String) async throws -> String {
        return "Weather for \(city): Sunny, 25°C"
    }
    
    func convert(_ input: CallTool.Parameters) async throws -> String {
        return try MCPTool<String, String>.extractParameter(input, name: "city")
    }
    
    func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        let input = try await convert(jsonInput)
        return try await handler(input: input)
    }
}

// Example 2: Complex input with multiple parameters and detailed descriptions
@Tool(name: "calculator", description: "Perform basic arithmetic operations")
struct CalculatorTool: MCPToolProtocol {

    struct CalculatorInput: Codable {
        /// First number in the calculation
        let a: Double
        /// Second number in the calculation
        let b: Double
        /// Operation to perform (add, subtract, multiply, divide)
        let operation: String
    }
    
    typealias Input = CalculatorInput
    typealias Output = Double
    
    /// Perform arithmetic operations on two numbers
    /// - Parameter input: The calculation input with a CalculatorInput object containing two numbers and an operation
    func handler(input: CalculatorInput) async throws -> Double {
        switch input.operation {
        case "add":
            return input.a + input.b
        case "subtract":
            return input.a - input.b
        case "multiply":
            return input.a * input.b
        case "divide":
            guard input.b != 0 else {
                throw MCPServerError.invalidParam("b", "Cannot divide by zero")
            }
            return input.a / input.b
        default:
            throw MCPServerError.invalidParam("operation", "Unknown operation: \(input.operation)")
        }
    }
    
    func convert(_ input: CallTool.Parameters) async throws -> CalculatorInput {
        let data = try JSONEncoder().encode(input.arguments)
        return try JSONDecoder().decode(CalculatorInput.self, from: data)
    }
    
    func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        let convertedInput = try await convert(jsonInput)
        return try await handler(input: convertedInput)
    }
}

// Example 3: Tool with existing properties (should only generate inputSchema)
@Tool
struct ExistingPropertiesTool: MCPToolProtocol {
    typealias Input = String
    typealias Output = String
    
    let name = "existing-tool"
    let description = "This tool already has name and description"
    
    /// Process text input with custom transformation
    /// - Parameter input: The text to process and transform
    func handler(input text: String) async throws -> String {
        return "Processed: \(text.uppercased())"
    }
    
    func convert(_ input: CallTool.Parameters) async throws -> String {
        return try MCPTool<String, String>.extractParameter(input, name: "text")
    }
    
    func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        let convertedInput = try await convert(jsonInput)
        return try await handler(input: convertedInput)
    }
}

// Example 4: Tool using external input type

// External input type with @SchemaDefinition
@SchemaDefinition
struct ExternalCalculatorInput: Codable {
    /// First number in the external calculation A
    let a: Double
    /// Second number in the external calculation B
    let b: Double
    /// Operation to perform (add, subtract, multiply, divide)
    let operation: String
}

@Tool(name: "external-calculator", description: "Perform arithmetic", schema: ExternalCalculatorInput.self)
struct ExternalCalculatorTool: MCPToolProtocol {
    typealias Input = ExternalCalculatorInput
    typealias Output = Double
    var i = 8

    /// Perform arithmetic operations 
    /// - Parameter input: The calculation input
    func handler(input: ExternalCalculatorInput) async throws -> Double {
        switch input.operation {
        case "add":
            return input.a + input.b
        case "subtract":
            return input.a - input.b
        case "multiply":
            return input.a * input.b
        case "divide":
            guard input.b != 0 else {
                throw MCPServerError.invalidParam("b", "Cannot divide by zero")
            }
            return input.a / input.b
        default:
            throw MCPServerError.invalidParam("operation", "Unknown operation: \(input.operation)")
        }
    }
    
	func convert(_ input: CallTool.Parameters) async throws -> ExternalCalculatorInput  {
        let data = try JSONEncoder().encode(input.arguments)
        return try JSONDecoder().decode(ExternalCalculatorInput.self, from: data)
    }
    
    func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        let convertedInput = try await convert(jsonInput)
        return try await handler(input: convertedInput)
    }
}

// Demonstration
@main
struct ToolMacroClient {
    static func main() async {
        print("=== MCP Tool DocC Schema Generation Demo ===\n")
        
        // Example 1: Weather Tool (String input with DocC-generated schema)
        let weatherTool = WeatherTool()
        print("Weather Tool:")
        print("  Name: \(weatherTool.name)")
        print("  Description: \(weatherTool.description)")
        print("  Schema: \(weatherTool.inputSchema)")
        print()
        
        // Example 2: Calculator Tool (Complex input with DocC description)
        let calculatorTool = CalculatorTool()
        print("Calculator Tool:")
        print("  Name: \(calculatorTool.name)")
        print("  Description: \(calculatorTool.description)")
        print("  Schema: \(calculatorTool.inputSchema)")
        print()
        
        // Example 3: Tool with existing properties
        let existingTool = ExistingPropertiesTool()
        print("Existing Properties Tool:")
        print("  Name: \(existingTool.name)")
        print("  Description: \(existingTool.description)")
        print("  Schema: \(existingTool.inputSchema)")
        print()
        
        // Example 4: Tool with external input type
        let externalTool = ExternalCalculatorTool()
        print("External Calculator Tool:")
        print("  Name: \(externalTool.name)")
        print("  Description: \(externalTool.description)")
        print("  Schema: \(externalTool.inputSchema)")
        print()
        
        // Show the schema generated by @SchemaDefinition
        // print("External Input Type Schema:")
        // print("  \(ExternalCalculatorInput.schema)")
        // print()
        
        print("=== DocC-Based Schema Generation Complete ===")
        print("✅ Schemas generated from DocC comments")
        print("✅ Parameter descriptions included")
        print("✅ External type definitions supported")
        print("✅ Compile-time validation performed")
        print("✅ No external JSON libraries required")
    }
}
