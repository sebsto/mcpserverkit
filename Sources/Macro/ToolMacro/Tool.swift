/// A macro that generates MCP tool properties with JSON schema for input validation.
///
/// This macro supports two modes of schema generation:
/// 1. **Schema Type Mode**: When a `schema` parameter is provided with a Schema-conformant type,
///    the JSON schema is extracted from that type's static `schema` property.
/// 2. **DocC Mode**: When no schema parameter is provided, the macro analyzes DocC comments
///    on the `handler` function to extract parameter descriptions and generate the schema.
///
/// Usage with Schema type:
/// ```swift
/// @SchemaDefinition
/// struct WeatherInput: Codable {
///     /// The city name to get weather for
///     let city: String
///     /// Temperature unit (celsius or fahrenheit)
///     let unit: String?
/// }
///
/// @Tool(name: "weather", description: "Get weather information", schema: WeatherInput.self)
/// struct WeatherTool: MCPToolProtocol {
///     // The macro will use WeatherInput.schema for inputSchema
/// }
/// ```
///
/// Usage with DocC comments:
/// ```swift
/// @Tool(name: "weather", description: "Get weather information")
/// struct WeatherTool: MCPToolProtocol {
///     typealias Input = String
///     
///     /// Get weather information for a specific city
///     /// - Parameter city: The city name to get the weather for
///     func handler(input city: String) async throws -> String {
///         // Implementation
///     }
///     
///     // The macro will generate schema from DocC comments:
///     // var inputSchema: String {
///     //     return """
///     //     {
///     //         "type": "object",
///     //         "properties": {
///     //             "city": {
///     //                 "type": "string",
///     //                 "description": "The city name to get the weather for"
///     //             }
///     //         },
///     //         "required": ["city"]
///     //     }
///     //     """
///     // }
/// }
/// ```
///
/// Features:
/// - **Flexible Schema Sources**: Use either Schema-conformant types or DocC comments
/// - **Schema Type Integration**: Seamlessly works with `@SchemaDefinition` annotated types
/// - **DocC Analysis**: Extracts parameter descriptions from function documentation
/// - **Compile-time Validation**: Validates parameter consistency and provides error reporting
/// - **Optional Properties**: Supports optional name and description parameters
///
/// Requirements:
/// - When using schema parameter: The type must conform to `Schema` protocol (added automatically by the @SchemaDefinition macro)
/// - When using DocC mode: The handler function must have DocC comments with parameter descriptions
/// - Parameter names in DocC must match function parameter names (for DocC mode)
@attached(member, names: named(name), named(description), named(inputSchema), named(handle))
public macro Tool(name: String? = nil, description: String? = nil, schema: Schema.Type? = nil) = #externalMacro(module: "ToolMacroImplementation", type: "ToolMacro")
