import MCP
import MCPServerKit
import DocSchemaMacro

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// This tool provides foreign exchange rates between currencies using the Hexarate API.

@SchemaDefinition
// Input structure for the FX rates tool.
// The docc headers will be used to generate the description in the JSON schema 
struct FXRatesInput: Codable {
    /// The source currency code (e.g., USD, EUR, GBP)
    /// Must be a valid 3-letter ISO 4217 currency code.
    /// Example: "USD" for US Dollar, "EUR" for Euro.
    /// RegEx pattern: ^[A-Z]{3}$   
    let sourceCurrency: String
    
    /// The target currency code (e.g., USD, EUR, GBP)
    /// Must be a valid 3-letter ISO 4217 currency code.
    /// Example: "USD" for US Dollar, "EUR" for Euro.
    /// RegEx pattern: ^[A-Z]{3}$
    let targetCurrency: String
    
    enum CodingKeys: String, CodingKey {
        case sourceCurrency = "source_currency"
        case targetCurrency = "target_currency"
    }
}

// JSON schema for the FX rates tool input
// let fxRatesToolSchema = """
// {
//     "type": "object",
//     "properties": {
//         "source_currency": {
//             "description": "The source currency code (e.g., USD, EUR, GBP)",
//             "type": "string",
//             "pattern": "^[A-Z]{3}$"
//         },
//         "target_currency": {
//             "description": "The target currency code (e.g., USD, EUR, GBP)",
//             "type": "string",
//             "pattern": "^[A-Z]{3}$"
//         }
//     },
//     "required": [
//         "source_currency",
//         "target_currency"
//     ]
// }
// """

@DocSchema(name: "foreign_exchange_rates", description: "Get current foreign exchange rates between two currencies. This tool uses the Hexarate API to provide real-time exchange rates. Supports major world currencies using standard 3-letter currency codes (ISO 4217). Returns the current exchange rate from the source currency to the target currency.", schema: FXRatesInput.self)
struct FXRateTool: MCPToolProtocol {
    typealias Input = FXRatesInput
    typealias Output = String

    // Fetches foreign exchange rates from the Hexarate API.
    func handler(input: FXRatesInput) async throws -> String {
        // Construct the API URL using the Hexarate API
        let fxURL = "https://hexarate.paikama.co/api/rates/latest/\(input.sourceCurrency)?target=\(input.targetCurrency)"
        let url = URL(string: fxURL)
        guard let url else {
            throw MCPServerError.invalidParam("currency", "\(input.sourceCurrency) or \(input.targetCurrency)")
        }
        let (data, _) = try await URLSession.shared.data(from: url)

        // return the data as a string
        return String(decoding: data, as: UTF8.self)
    }
    
    func convert(_ params: CallTool.Parameters) async throws -> FXRatesInput {
        // Extract the parameters and create a FXRatesInput using the same pattern as calculator
        let data = try JSONEncoder().encode(params.arguments)
        let input = try JSONDecoder().decode(FXRatesInput.self, from: data)
        
        // Validate currency codes (should be 3 uppercase letters) using Swift 6 regex
        let currencyRegex = /^[A-Z]{3}$/
        
        guard input.sourceCurrency.wholeMatch(of: currencyRegex) != nil else {
            throw MCPServerError.invalidParam("source_currency", "Must be a 3-letter currency code (e.g., USD)")
        }
        
        guard input.targetCurrency.wholeMatch(of: currencyRegex) != nil else {
            throw MCPServerError.invalidParam("target_currency", "Must be a 3-letter currency code (e.g., EUR)")
        }
        
        return FXRatesInput(sourceCurrency: input.sourceCurrency.uppercased(), targetCurrency: input.targetCurrency.uppercased())
    }
    
    func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        let input = try await convert(jsonInput)
        return try await handler(input: input)
    }
}

// Optional: Create a prompt for the FX rates tool
let fxRatesPrompt = try! MCPPrompt.build { builder in
    builder.name = "exchange-rate"
    builder.description = "A prompt asking for the current exchange rate between two currencies"
    builder.text("What is the current exchange rate from {source_currency} to {target_currency}?")
    builder.parameter("source_currency", description: "the 3-letter code of the source currency (e.g., USD)")
    builder.parameter("target_currency", description: "the 3-letter code of the target currency (e.g., EUR)")
}
