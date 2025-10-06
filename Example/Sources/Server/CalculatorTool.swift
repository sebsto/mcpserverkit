import AgentKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// This tool performs basic arithmetic operations.

// Define a struct for calculator input
@SchemaDefinition
struct CalculatorInput: Codable {
    /// the first operand of the operation
    let a: Double
    /// the second operand of the operation
    let b: Double
    /// the arithmetic operation, expressed as a string : "add", "substract", "multiply", "divide"
    let operation: String
}

// Create the calculator tool
@Tool(
    name: "calculator",
    description: "Performs basic arithmetic operations (add, subtract, multiply, divide)",
    schema: CalculatorInput.self
)
struct CalculatorTool {
    func handle(input: CalculatorInput) async throws -> Double {
        // Perform the calculation based on the operation
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
}
