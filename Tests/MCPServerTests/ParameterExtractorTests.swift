// import MCPServerKit
// import Testing

// @Suite("ParameterExtractorTests")
// struct ParameterExtractorTests {

//     @Test("Test basic parameter extraction")
//     func testBasicParameterExtraction() {
//         let input = "This is a test with {param1: first parameter} and {param2: second parameter}"
//         let parameters = extractPromptParameters(from: input)

//         #expect(parameters.count == 2)
//         #expect(parameters[0].name == "param1")
//         #expect(parameters[0].description == "first parameter")
//         #expect(parameters[1].name == "param2")
//         #expect(parameters[1].description == "second parameter")
//     }

//     @Test("Test parameter extraction with whitespace")
//     func testParameterExtractionWithWhitespace() {
//         let input = "Test with {  param1  :  first parameter  } and {  param2  :  second parameter  }"
//         let parameters = extractParameters(from: input)

//         #expect(parameters.count == 2)
//         #expect(parameters[0].name == "param1")
//         #expect(parameters[0].description == "first parameter")
//         #expect(parameters[1].name == "param2")
//         #expect(parameters[1].description == "second parameter")
//     }

//     @Test("Test parameter extraction with no parameters")
//     func testParameterExtractionWithNoParameters() {
//         let input = "This is a test with no parameters"
//         let parameters = extractParameters(from: input)

//         #expect(parameters.isEmpty)
//     }

//     @Test("Test parameter extraction with invalid format")
//     func testParameterExtractionWithInvalidFormat() {
//         let input = "Test with {param1} and {param2:} and {:param3}"
//         let parameters = extractParameters(from: input)

//         #expect(parameters.isEmpty)
//     }

//     @Test("Test parameter extraction with nested braces")
//     func testParameterExtractionWithNestedBraces() {
//         let input = "Test with {param1: {nested: value}} and {param2: second parameter}"
//         let parameters = extractParameters(from: input)

//         #expect(parameters.count == 2)
//         #expect(parameters[0].name == "param1")
//         #expect(parameters[0].description == "{nested: value}")
//         #expect(parameters[1].name == "param2")
//         #expect(parameters[1].description == "second parameter")
//     }
// }
