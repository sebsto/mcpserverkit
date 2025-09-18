import BedrockService
import Logging

extension Agent {

    internal func runLoop(
        initialPrompt: String,
        systemPrompt: String,
        bedrock: BedrockService,
        model: BedrockModel,
        // tools: [MCPClient],
        logger: Logger
    ) async throws {

        // verify that the model supports tool usage
        guard model.hasConverseModality(.toolUse) else {
            logger.error("Model does not support converse tools", metadata: ["model": "\(model)"])
            throw AgentError.modelNotSupported(model)
        }

        // variables we're going to reuse for the duration of the conversation
        var messages: History = []
        var requestBuilder: ConverseRequestBuilder? = nil
        // convert MCP Tools to Bedrock Tools
        // let bedrockTools = try await tools.bedrockTools()

        // is it our first request ?
        if requestBuilder == nil {
            requestBuilder = try ConverseRequestBuilder(with: model)
                .withHistory(messages)
                .withPrompt(initialPrompt)
            // .withTools(bedrockTools)
            if !systemPrompt.isEmpty {
                requestBuilder = try requestBuilder!.withSystemPrompt(systemPrompt)
            }
        } else {
            // if not, we can just add the prompt to the existing request builder
            requestBuilder = try ConverseRequestBuilder(from: requestBuilder!)
                .withHistory(messages)
            // .withPrompt(prompt)
        }

        // add the prompt to the history
        messages.append(.init(initialPrompt))

        // loop on calling the model while the last message is NOT text
        // in other words, has long as we receive toolUse, call the tool, call the model again and iterate until the lats message is text.
        // TODO : how to manage reasoning ?
        var lastMessageIsText = false
        repeat {
            logger.debug("Calling ConverseStream")
            let reply = try await bedrock.converseStream(with: requestBuilder!)
            for try await element: ConverseStreamElement in reply.stream {

                // read the stream of elements.  If this is a text content, print it.
                // otherwise, collect the message.
                switch element {
                case .text(_, let text):
                    print(text, terminator: "")
                case .toolUse(_, let toolUse):
                    logger.trace("Tool Use", metadata: ["toolUse": "\(toolUse.name)"])
                case .messageComplete(let message):
                    messages.append(message)
                    print("\n")
                case .metaData(let metadata):
                    logger.trace("Metadata", metadata: ["metadata": "\(metadata)"])
                default:
                    break
                }
            }

            // If the last message is toolUse, invoke the tool and
            // continue the conversation with the tool result.
            logger.debug("Have receive a complete message, checking is this is tool use?")
            if let msg = messages.last,
                let toolUse = msg.getToolUse()
            {

                fatalError("not implemented yet")
                // logger.trace("Last message", metadata: ["message": "\(msg)"])
                // logger.debug("Yes, let's use a tool", metadata: ["toolUse": "\(toolUse.name)"])

                // requestBuilder = try await resolveToolUse(
                //     bedrock: bedrock,
                //     requestBuilder: requestBuilder!,
                //     tools: tools,
                //     toolUse: toolUse,
                //     messages: &messages,
                //     logger: logger
                // )

                // // add the tool result to the history
                // if let toolResult = requestBuilder?.toolResult {
                //     logger.debug("Tool Result", metadata: ["result": "\(toolResult)"])
                //     messages.append(.init(toolResult))
                // } else {
                //     logger.warning("No tool result found, this is unexpected")
                // }

            } else {
                logger.debug("No, checking if the last message is text")
                if messages.last?.hasTextContent() == true {
                    lastMessageIsText = true
                    logger.debug("yes, exiting the loop and ask next question to the user")
                } else {
                    logger.warning("Last message is not text nor tool use, break out the loop")
                    logger.debug(
                        "Last message",
                        metadata: ["message": "\(String(describing: messages.last))"]
                    )
                    lastMessageIsText = false
                }
            }
        } while lastMessageIsText == false
    }
}
