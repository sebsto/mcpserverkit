import MCP

#if canImport(FoundationEssentials)
import FoundatioNEssentials
#else
import Foundation
#endif

public protocol MCPToolProtocol<Input, Output>: Sendable {
    associatedtype Input
    associatedtype Output

    var name: String { get }
    var description: String { get }

    // FIXME: we need a way to generate this from the actual handler type :-)
    var inputSchema: String { get }

    // a generic handler
    func handler(_ input: Input) async throws -> Output

    // convert the input from the CallTool.Parameters to the expected type
    func convert(_ input: CallTool.Parameters) async throws -> Input
}
