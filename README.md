# MCP2Lambda (Swift Implementation)

This is a Swift 6 implementation of the MCP2Lambda project, which allows you to run any AWS Lambda function as a Large Language Model (LLM) tool without code changes using Anthropic's Model Context Protocol (MCP).

## Overview

MCP2Lambda enables LLMs to interact with AWS Lambda functions as tools, extending their capabilities beyond text generation. This allows models to:

- Access real-time and private data, including data sources in your VPCs
- Execute custom code using a Lambda function as sandbox environment
- Interact with external services and APIs using Lambda functions internet access (and bandwidth)
- Perform specialized calculations or data processing

## Prerequisites

- Swift 6.0 or higher
- AWS account with configured credentials
- AWS Lambda functions (sample functions provided in the repo)
- An application using Amazon Bedrock with the Converse API

## Project Structure

The project is organized as follows:

- `Sources/MCPCore`: Core library for MCP protocol implementation
- `Sources/MCP2Lambda`: Main server application that bridges MCP and AWS Lambda
- `Sources/MCPClientBedrock`: Client application that connects to Amazon Bedrock
- `sample_functions/swift`: Sample Lambda functions implemented in Swift

## Installation

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/sebsto/mcp2lambda-swift.git
   cd mcp2lambda-swift
   ```

2. Build the project:
   ```
   swift build
   ```

3. Run the server:
   ```
   swift run MCP2Lambda
   ```

### Using Docker

1. Build the Docker image:
   ```
   docker build -t mcp2lambda-swift .
   ```

2. Run the container:
   ```
   docker run -p 8080:8080 mcp2lambda-swift
   ```

## Configuration

The MCP2Lambda server can be configured using command-line arguments or environment variables:

- `--region` or `AWS_REGION`: AWS region to use (default: us-east-1)
- `--function-prefix` or `FUNCTION_PREFIX`: Prefix for Lambda functions to include (default: mcp2lambda-)
- `--function-list` or `FUNCTION_LIST`: JSON array of allowed function names (default: [])
- `--no-pre-discovery` or `PRE_DISCOVERY=false`: Disable registering Lambda functions as individual tools at startup

## Strategy Selection

The gateway supports two different strategies for handling Lambda functions:

1. **Pre-Discovery Mode** (default: enabled): Registers each Lambda function as an individual tool at startup. This provides a more intuitive interface where each function appears as its own named tool.

2. **Generic Mode**: Uses two generic tools (`list_lambda_functions` and `invoke_lambda_function`) to interact with Lambda functions.

## Sample Lambda Functions

The repository includes three sample Lambda functions implemented in Swift:

1. **CustomerIdFromEmail**: Retrieves a customer ID based on an email address.
2. **CustomerInfoFromId**: Retrieves detailed customer information based on a customer ID.
3. **RunPythonCode**: Executes arbitrary Python code within a Lambda sandbox environment.

### Deploying Sample Functions

1. Install the AWS SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

2. Deploy the sample functions:
   ```
   cd sample_functions/swift
   sam build
   sam deploy
   ```

## Using with Amazon Bedrock

The MCPClientBedrock application connects MCP2Lambda to Amazon Bedrock models:

1. Start the MCP2Lambda server:
   ```
   swift run MCP2Lambda
   ```

2. Run the Bedrock client:
   ```
   swift run MCPClientBedrock
   ```

3. Interact with the model through the command-line interface.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
