# MCP2Lambda Swift Implementation Notes

This document contains notes and information about the MCP2Lambda Swift implementation.

## Project Overview

MCP2Lambda is a Swift 6 implementation of a gateway that allows you to run any AWS Lambda function as a Large Language Model (LLM) tool without code changes using Anthropic's Model Context Protocol (MCP).

## Development Notes

### Swift 6 Concurrency

The project uses Swift 6's modern concurrency features:
- Actors for thread safety
- Async/await for asynchronous operations
- Sendable for data safety across concurrency domains

### Key Components

1. **MCPCore**: Core library implementing the MCP protocol
   - MCPServer protocol defining server functionality
   - VaporMCPServer implementation using Vapor web framework
   - Models for MCP protocol communication

2. **MCP2Lambda**: Main server application
   - Bridges MCP and AWS Lambda
   - Supports dynamic discovery of Lambda functions
   - Registers Lambda functions as tools

3. **MCPClientBedrock**: Client application
   - Connects to Amazon Bedrock models
   - Uses MCP to provide tools to the model

### Testing

Tests are implemented using Swift 6's new Testing framework, which replaces XCTest.

## Troubleshooting

Common issues:
- Ensure Swift 6.0 or higher is installed
- Check AWS credentials are properly configured
- Verify Lambda functions have the correct permissions
- Ensure Bedrock API access is properly set up

## Future Improvements

- Add more comprehensive error handling
- Improve documentation
- Add more test coverage
- Support for additional AWS services
