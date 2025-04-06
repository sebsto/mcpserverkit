import MCP
import MCPServerKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// This tool performs basic arithmetic operations.

// Define the calculator tool schema
let calculatorSchema = """
{
    "type": "object",
    "properties": {
      "a": {
        "description": "First number",
        "type": "number"
      },
      "b": {
        "description": "Second number",
        "type": "number"
      },
      "operation": {
        "description": "Operation to perform (add, subtract, multiply, divide)",
        "type": "string",
        "enum": ["add", "subtract", "multiply", "divide"]
      }
    },
    "required": [
      "a",
      "b",
      "operation"
    ]
}
"""

// Define a struct for calculator input
struct CalculatorInput: Codable {
    let a: Double
    let b: Double
    let operation: String
}

// Create the calculator tool
let calculatorTool = MCPTool<CalculatorInput, Double>(
    name: "calculator",
    description: "Performs basic arithmetic operations (add, subtract, multiply, divide)",
    inputSchema: calculatorSchema,
    converter: { params in
        // Extract the parameters and create a CalculatorInput
        let data = try JSONEncoder().encode(params.arguments)
        return try JSONDecoder().decode(CalculatorInput.self, from: data)
    },
    body: { (input: CalculatorInput) async throws -> Double in
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
)
