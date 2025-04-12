import XCTest
import Testing
import MCP
@testable import MCPServerKit

@Suite("MCPResource Tests")
struct MCPResourceTests {
    
    @Test("Creating a text resource with enum MIME type")
    func testCreateTextResourceWithEnumMimeType() {
        let name = "Documentation"
        let uri = "docs://api-reference"
        let content = "# API Reference\n\nThis document describes..."
        let description = "API documentation for developers"
        let mimeType = MCPResource.MIMEType.markdown
        
        let resource = MCPResource.text(
            name: name,
            uri: uri,
            content: content,
            description: description,
            mimeType: mimeType
        )
        
        // Verify resource properties
        #expect(resource.resource.name == name)
        #expect(resource.resource.uri == uri)
        #expect(resource.resource.description == description)
        #expect(resource.resource.mimeType == mimeType.value)
        
        // Verify content properties
        #expect(resource.content.uri == uri)
        #expect(resource.content.mimeType == mimeType.value)
        #expect(resource.content.text == content)
        #expect(resource.content.blob == nil)
    }
    
    @Test("Creating a text resource with string MIME type")
    func testCreateTextResourceWithStringMimeType() {
        let name = "Documentation"
        let uri = "docs://api-reference"
        let content = "# API Reference\n\nThis document describes..."
        let description = "API documentation for developers"
        let mimeType = "text/markdown"
        
        let resource = MCPResource.text(
            name: name,
            uri: uri,
            content: content,
            description: description,
            mimeTypeString: mimeType
        )
        
        // Verify resource properties
        #expect(resource.resource.name == name)
        #expect(resource.resource.uri == uri)
        #expect(resource.resource.description == description)
        #expect(resource.resource.mimeType == mimeType)
        
        // Verify content properties
        #expect(resource.content.uri == uri)
        #expect(resource.content.mimeType == mimeType)
        #expect(resource.content.text == content)
        #expect(resource.content.blob == nil)
    }
    
    @Test("Creating a binary resource with enum MIME type")
    func testCreateBinaryResourceWithEnumMimeType() {
        let name = "Logo"
        let uri = "images://logo"
        let data = Data([0x01, 0x02, 0x03, 0x04])
        let description = "Company logo"
        let mimeType = MCPResource.MIMEType.png
        
        let resource = MCPResource.binary(
            name: name,
            uri: uri,
            data: data,
            description: description,
            mimeType: mimeType
        )
        
        // Verify resource properties
        #expect(resource.resource.name == name)
        #expect(resource.resource.uri == uri)
        #expect(resource.resource.description == description)
        #expect(resource.resource.mimeType == mimeType.value)
        
        // Verify content properties
        #expect(resource.content.uri == uri)
        #expect(resource.content.mimeType == mimeType.value)
        #expect(resource.content.text == nil)
        #expect(resource.content.blob == data.base64EncodedString())
    }
    
    @Test("Creating a binary resource with string MIME type")
    func testCreateBinaryResourceWithStringMimeType() {
        let name = "Logo"
        let uri = "images://logo"
        let data = Data([0x01, 0x02, 0x03, 0x04])
        let description = "Company logo"
        let mimeType = "image/png"
        
        let resource = MCPResource.binary(
            name: name,
            uri: uri,
            data: data,
            description: description,
            mimeTypeString: mimeType
        )
        
        // Verify resource properties
        #expect(resource.resource.name == name)
        #expect(resource.resource.uri == uri)
        #expect(resource.resource.description == description)
        #expect(resource.resource.mimeType == mimeType)
        
        // Verify content properties
        #expect(resource.content.uri == uri)
        #expect(resource.content.mimeType == mimeType)
        #expect(resource.content.text == nil)
        #expect(resource.content.blob == data.base64EncodedString())
    }
    
    @Test("Resource registry operations")
    func testResourceRegistry() {
        let registry = MCPResourceRegistry()
        
        // Create test resources
        let textResource = MCPResource.text(
            name: "Text",
            uri: "text://sample",
            content: "Sample text",
            mimeType: .plainText
        )
        
        let binaryResource = MCPResource.binary(
            name: "Binary",
            uri: "binary://sample",
            data: Data([0x01, 0x02, 0x03, 0x04]),
            mimeType: .png
        )
        
        // Test adding resources
        registry.add(textResource)
        #expect(registry.resources.count == 1)
        
        registry.add(binaryResource)
        #expect(registry.resources.count == 2)
        
        // Test finding resources
        let foundText = registry.find(uri: "text://sample")
        #expect(foundText != nil)
        #expect(foundText?.resource.name == "Text")
        
        let foundBinary = registry.find(uri: "binary://sample")
        #expect(foundBinary != nil)
        #expect(foundBinary?.resource.name == "Binary")
        
        let notFound = registry.find(uri: "nonexistent://uri")
        #expect(notFound == nil)
        
        // Test removing resources
        registry.remove(uri: "text://sample")
        #expect(registry.resources.count == 1)
        #expect(registry.find(uri: "text://sample") == nil)
        #expect(registry.find(uri: "binary://sample") != nil)
        
        // Test conversion methods
        let mcpResources = registry.asMCPResources()
        #expect(mcpResources.count == 1)
        #expect(mcpResources[0].name == "Binary")
        
        let contentMap = registry.asContentMap()
        #expect(contentMap.count == 1)
        #expect(contentMap["binary://sample"] != nil)
    }
    
    @Test("Adding multiple resources at once")
    func testAddMultipleResources() {
        let registry = MCPResourceRegistry()
        
        let resource1 = MCPResource.text(name: "Resource1", uri: "res://1", content: "Content 1", mimeType: .plainText)
        let resource2 = MCPResource.text(name: "Resource2", uri: "res://2", content: "Content 2", mimeType: .plainText)
        let resource3 = MCPResource.text(name: "Resource3", uri: "res://3", content: "Content 3", mimeType: .plainText)
        
        // Test adding array of resources
        registry.add([resource1, resource2])
        #expect(registry.resources.count == 2)
        
        // Test adding variadic resources
        registry.add(resource3)
        #expect(registry.resources.count == 3)
        
        // Verify all resources were added
        #expect(registry.find(uri: "res://1") != nil)
        #expect(registry.find(uri: "res://2") != nil)
        #expect(registry.find(uri: "res://3") != nil)
    }
    
    @Test("Creating registry with initial resources")
    func testRegistryWithInitialResources() {
        let resource1 = MCPResource.text(name: "Resource1", uri: "res://1", content: "Content 1", mimeType: .plainText)
        let resource2 = MCPResource.text(name: "Resource2", uri: "res://2", content: "Content 2", mimeType: .plainText)
        
        let registry = MCPResourceRegistry(resources: [resource1, resource2])
        
        #expect(registry.resources.count == 2)
        #expect(registry.find(uri: "res://1") != nil)
        #expect(registry.find(uri: "res://2") != nil)
    }
    
    @Test("MIME type detection")
    func testMimeTypeDetection() throws {
        // Create a temporary file for testing
        let tempDir = FileManager.default.temporaryDirectory
        let textFilePath = tempDir.appendingPathComponent("test.md").path
        let textContent = "# Test Markdown\n\nThis is a test."
        
        try textContent.write(toFile: textFilePath, atomically: true, encoding: .utf8)
        
        // Test file resource creation with automatic MIME type detection
        let resource = try MCPResource.file(
            name: "Test Markdown",
            uri: "file://test.md",
            filePath: textFilePath,
            mimeType: .markdown
        )
        
        #expect(resource.resource.mimeType == "text/markdown")
        #expect(resource.content.text == textContent)
        
        // Clean up
        try FileManager.default.removeItem(atPath: textFilePath)
    }
    
    @Test("MIME type enum properties")
    func testMimeTypeEnumProperties() {
        // Test text detection
        #expect(MCPResource.MIMEType.plainText.isText == true)
        #expect(MCPResource.MIMEType.html.isText == true)
        #expect(MCPResource.MIMEType.json.isText == true)
        #expect(MCPResource.MIMEType.xml.isText == true)
        
        // Test non-text types
        #expect(MCPResource.MIMEType.png.isText == false)
        #expect(MCPResource.MIMEType.jpeg.isText == false)
        #expect(MCPResource.MIMEType.pdf.isText == false)
        
        // Test value property
        #expect(MCPResource.MIMEType.markdown.value == "text/markdown")
        #expect(MCPResource.MIMEType.json.value == "application/json")
        #expect(MCPResource.MIMEType.png.value == "image/png")
    }
}
