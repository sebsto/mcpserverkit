import Foundation

/// A structure representing a parameter extracted from a string
public struct ExtractedParameter {
    /// The name of the parameter
    public let name: String
    /// The description of the parameter
    public let description: String
}

/// Extracts parameters from a string where parameters are enclosed in curly braces
/// and follow the format {parameterName: parameterDescription}
/// - Parameter input: The string to extract parameters from
/// - Returns: An array of extracted parameters
public func extractParameters(from input: String) -> [ExtractedParameter] {
    var parameters: [ExtractedParameter] = []

    // Match pattern: opening brace, followed by parameter name (non-colon, non-brace chars),
    // colon with optional whitespace, then description (which can contain nested braces),
    // followed by closing brace
    let pattern = #/\{\s*([^:{}\s][^:{}]*?)?\s*:\s*((?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*)\s*\}/#

    for match in input.matches(of: pattern) {
        let name = String(match.1 ?? "").trimmingCharacters(in: .whitespaces)
        let description = String(match.2).trimmingCharacters(in: .whitespaces)

        // Only add parameters that have both name and description
        if !name.isEmpty && !description.isEmpty {
            parameters.append(ExtractedParameter(name: name, description: description))
        }
    }

    return parameters
}
