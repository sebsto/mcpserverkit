#if MCPMacros

@_exported import ToolShared

/// A macro that adds a static `schema` property containing an OpenAPI-compatible JSON schema definition.
///
/// This macro generates a static `schema` property that provides a JSON schema representation
/// of the struct, making it compatible with MCP tools and other systems that require
/// OpenAPI schema definitions.
///
/// Usage:
/// ```swift
/// @SchemaDefinition
/// struct WeatherInput: Codable {
///     let city: String
///     let unit: String?
///     let includeForecast: Bool
/// }
///
/// // The macro adds:
/// extension WeatherInput: Schema {
///     static var schema: String {
///         // Returns OpenAPI JSON schema definition of the struct
///     }
/// }
///
/// // You can then access the schema:
/// let schemaDefinition = WeatherInput.schema
/// ```
///
/// Features:
/// - **Static Schema Property**: Adds a `schema` property to the type
/// - **OpenAPI Compatible**: Generates JSON schema following OpenAPI specifications
/// - **Protocol Conformance**: Adds `Schema` protocol conformance
/// - **Compile-time Generation**: Schema is generated at compile time
///
/// Requirements:
/// - Apply to structs that need schema definitions
/// - Struct should be `Codable` for consistency with JSON operations
///
/// This macro is commonly used with `@Tool` to provide schema definitions
/// for MCP tool input types.
@attached(member, names: named(schema))
@attached(extension, conformances: Schema)
public macro SchemaDefinition() = #externalMacro(module: "ToolMacroImplementation", type: "SchemaDefinitionMacro")

#endif
