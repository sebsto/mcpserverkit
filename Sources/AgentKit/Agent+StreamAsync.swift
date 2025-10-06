extension Agent {
    /// Stream events from an agent asynchronously.
    ///
    /// - Parameter message: The message to send to the agent.
    /// - Returns: An async throwing stream of events from the agent.
    public func streamAsync(_ message: String) -> AsyncThrowingStream<AgentCallbackEvent, Error> {
        AsyncThrowingStream(AgentCallbackEvent.self) { continuation in
            let t = Task {
                do {
                    try await self(message) { event in
                        if case .end = event {
                            continuation.finish()
                        }
                        continuation.yield(event)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                t.cancel()
            }
        }
    }
}
