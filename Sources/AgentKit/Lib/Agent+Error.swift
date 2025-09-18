import BedrockService

extension Agent {
    public enum AgentError: Error {
        case modelNotSupported(BedrockModel)
    }
}
