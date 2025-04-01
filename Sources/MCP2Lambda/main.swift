import Foundation
import ArgumentParser
import MCPCore
import SotoLambda
import SotoCore

struct MCP2Lambda: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp2lambda",
        abstract: "MCP Gateway to AWS Lambda",
        subcommands: [],
        defaultSubcommand: nil
    )
    
    @Flag(name: .long, help: "Disable registering Lambda functions as individual tools at startup")
    var noPreDiscovery = false
    
    @Option(name: .long, help: "AWS region to use")
    var region = ProcessInfo.processInfo.environment["AWS_REGION"] ?? "us-east-1"
    
    @Option(name: .long, help: "Prefix for Lambda functions to include")
    var functionPrefix = ProcessInfo.processInfo.environment["FUNCTION_PREFIX"] ?? "mcp2lambda-"
    
    @Option(name: .long, help: "JSON array of allowed function names")
    var functionList = ProcessInfo.processInfo.environment["FUNCTION_LIST"] ?? "[]"
    
    mutating func run() async throws {
        // Determine if we should use pre-discovery mode
        let preDiscovery: Bool
        if let envValue = ProcessInfo.processInfo.environment["PRE_DISCOVERY"] {
            preDiscovery = envValue.lowercased() == "true"
        } else {
            preDiscovery = !noPreDiscovery
        }
        
        // Parse allowed function list
        let allowedFunctions: [String]
        do {
            allowedFunctions = try JSONDecoder().decode([String].self, from: functionList.data(using: .utf8)!)
        } catch {
            print("Error parsing function list: \(error)")
            throw error
        }
        
        // Create AWS Lambda client
        let awsClient = AWSClient(credentialProvider: .default, httpClientProvider: .createNew)
        let lambdaClient = Lambda(client: awsClient, region: .init(rawValue: region))
        
        // Create MCP server
        let mcp = try await VaporMCPServer(name: "MCP Gateway to AWS Lambda")
        
        // Register tools based on strategy
        if !preDiscovery {
            // Register generic tools
            print("Using generic Lambda tools strategy...")
            try await registerGenericTools(mcp: mcp, lambdaClient: lambdaClient, functionPrefix: functionPrefix, allowedFunctions: allowedFunctions)
        } else {
            // Register individual Lambda functions as tools
            print("Using dynamic Lambda function registration strategy...")
            try await registerDynamicTools(mcp: mcp, lambdaClient: lambdaClient, functionPrefix: functionPrefix, allowedFunctions: allowedFunctions)
        }
        
        // Run the server
        try await mcp.run()
    }
    
    func validateFunctionName(_ functionName: String, prefix: String, allowedList: [String]) -> Bool {
        return functionName.hasPrefix(prefix) || allowedList.contains(functionName)
    }
    
    func sanitizeToolName(_ name: String, prefix: String) -> String {
        // Remove prefix if present
        var result = name
        if result.hasPrefix(prefix) {
            result = String(result.dropFirst(prefix.count))
        }
        
        // Replace invalid characters with underscore
        result = result.replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "_", options: .regularExpression)
        
        // Ensure name doesn't start with a number
        if let firstChar = result.first, firstChar.isNumber {
            result = "_" + result
        }
        
        return result
    }
    
    func formatLambdaResponse(functionName: String, payload: Data) -> String {
        do {
            // Try to parse the payload as JSON
            let json = try JSONSerialization.jsonObject(with: payload)
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Invalid JSON"
            return "Function \(functionName) returned: \(jsonString)"
        } catch {
            // Return raw payload if not JSON
            return "Function \(functionName) returned payload: \(String(data: payload, encoding: .utf8) ?? "Invalid UTF-8")"
        }
    }
    
    func registerGenericTools(mcp: VaporMCPServer, lambdaClient: Lambda, functionPrefix: String, allowedFunctions: [String]) async throws {
        // Register list_lambda_functions tool
        await mcp.registerTool(
            name: "list_lambda_functions",
            description: """
                Tool that lists all AWS Lambda functions that you can call as tools.
                Use this list to understand what these functions are and what they do.
                This functions can help you in many different ways.
                """,
            handler: { context, _ in
                context.info("Calling AWS Lambda ListFunctions...")
                
                let functions = try await lambdaClient.listFunctions().get()
                
                context.info("Found \(functions.functions?.count ?? 0) functions")
                
                let functionsWithPrefix = functions.functions?.filter { function in
                    guard let name = function.functionName else { return false }
                    return self.validateFunctionName(name, prefix: functionPrefix, allowedList: allowedFunctions)
                } ?? []
                
                context.info("Found \(functionsWithPrefix.count) functions with prefix \(functionPrefix)")
                
                // Pass only function names and descriptions to the model
                let functionNamesAndDescriptions = functionsWithPrefix.map { function -> [String: String] in
                    var result: [String: String] = [:]
                    if let name = function.functionName {
                        result["FunctionName"] = name
                    }
                    if let description = function.description {
                        result["Description"] = description
                    }
                    return result
                }
                
                let jsonData = try JSONEncoder().encode(functionNamesAndDescriptions)
                return String(data: jsonData, encoding: .utf8) ?? "[]"
            }
        )
        
        // Register invoke_lambda_function tool
        await mcp.registerTool(
            name: "invoke_lambda_function",
            description: """
                Tool that invokes an AWS Lambda function with a JSON payload.
                Before using this tool, list the functions available to you.
                """,
            handler: { context, parameters in
                guard let functionName = parameters["function_name"] as? String else {
                    return "Missing function_name parameter"
                }
                
                if !self.validateFunctionName(functionName, prefix: functionPrefix, allowedList: allowedFunctions) {
                    return "Function \(functionName) is not valid"
                }
                
                let functionParams = parameters["parameters"] as? [String: Any] ?? [:]
                
                context.info("Invoking \(functionName) with parameters: \(functionParams)")
                
                // Convert parameters to JSON
                let payloadData = try JSONSerialization.data(withJSONObject: functionParams)
                
                // Invoke Lambda function
                let response = try await lambdaClient.invoke(.init(
                    functionName: functionName,
                    invocationType: .requestResponse,
                    payload: payloadData
                )).get()
                
                context.info("Function \(functionName) returned with status code: \(response.statusCode ?? 0)")
                
                if let functionError = response.functionError {
                    let errorMessage = "Function \(functionName) returned with error: \(functionError)"
                    context.error(errorMessage)
                    return errorMessage
                }
                
                guard let payload = response.payload else {
                    return "Function \(functionName) returned no payload"
                }
                
                // Format the response payload
                return self.formatLambdaResponse(functionName: functionName, payload: payload)
            }
        )
    }
    
    func registerDynamicTools(mcp: VaporMCPServer, lambdaClient: Lambda, functionPrefix: String, allowedFunctions: [String]) async throws {
        do {
            let functions = try await lambdaClient.listFunctions().get()
            
            let validFunctions = functions.functions?.filter { function in
                guard let name = function.functionName else { return false }
                return self.validateFunctionName(name, prefix: functionPrefix, allowedList: allowedFunctions)
            } ?? []
            
            print("Dynamically registering \(validFunctions.count) Lambda functions as tools...")
            
            for function in validFunctions {
                guard let functionName = function.functionName else { continue }
                let description = function.description ?? "AWS Lambda function: \(functionName)"
                
                // Extract information about parameters from the description if available
                var enhancedDescription = description
                if description.contains("Expected format:") {
                    if let parameterInfo = description.split(separator: "Expected format:").last?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        enhancedDescription = "\(description)\n\nParameters: \(parameterInfo)"
                    }
                }
                
                // Create a tool name from the function name
                let toolName = sanitizeToolName(functionName, prefix: functionPrefix)
                
                // Register the Lambda function as a tool
                await mcp.registerTool(
                    name: toolName,
                    description: enhancedDescription,
                    handler: { context, parameters in
                        context.info("Invoking \(functionName) with parameters: \(parameters)")
                        
                        // Convert parameters to JSON
                        let payloadData = try JSONSerialization.data(withJSONObject: parameters)
                        
                        // Invoke Lambda function
                        let response = try await lambdaClient.invoke(.init(
                            functionName: functionName,
                            invocationType: .requestResponse,
                            payload: payloadData
                        )).get()
                        
                        context.info("Function \(functionName) returned with status code: \(response.statusCode ?? 0)")
                        
                        if let functionError = response.functionError {
                            let errorMessage = "Function \(functionName) returned with error: \(functionError)"
                            context.error(errorMessage)
                            return errorMessage
                        }
                        
                        guard let payload = response.payload else {
                            return "Function \(functionName) returned no payload"
                        }
                        
                        // Format the response payload
                        return self.formatLambdaResponse(functionName: functionName, payload: payload)
                    }
                )
            }
            
            print("Lambda functions registered successfully as individual tools.")
        } catch {
            print("Error registering Lambda functions as tools: \(error)")
            print("Falling back to generic Lambda tools...")
            
            // Register the generic tool functions with MCP as fallback
            try await registerGenericTools(mcp: mcp, lambdaClient: lambdaClient, functionPrefix: functionPrefix, allowedFunctions: allowedFunctions)
        }
    }
}

// Run the command
@main
struct MCP2LambdaMain {
    static func main() async {
        await MCP2Lambda.main()
    }
}
