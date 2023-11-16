import MacroTesting
import UnbeatableDependenciesMacrosPlugin
import XCTest

final class AutoMockMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            // Set this to `true` to record all macro expansions (or use the `record` parameter
            // of `assertMacro`):
            isRecording: false,
            macros: [
                "AutoMock": AutoMockMacro.self
            ]
        ) {
            super.invokeTest()
        }
    }

    func testAutoMockMacroExpansion() {
        assertMacro {
            """
            @AutoMock
            public protocol MyProtocol {
                func doSomethingWithoutArguments()

                func doSomethingWithAComplexFunctionSignature(
                    _ a: Int,
                    _ b: String,
                    c: Bool,
                    d: (Int, String) -> Void
                ) async throws -> String
            }
            """
        } expansion: {
            """
            public protocol MyProtocol {
                func doSomethingWithoutArguments()

                func doSomethingWithAComplexFunctionSignature(
                    _ a: Int,
                    _ b: String,
                    c: Bool,
                    d: (Int, String) -> Void
                ) async throws -> String
            }

            public struct MyProtocolMock: MyProtocol {
                public init() {
                }
                public var _doSomethingWithoutArguments: () -> Void = {
                    XCTFail("Unimplemented")
                }
                public func doSomethingWithoutArguments() {
                    _doSomethingWithoutArguments()
                }
                public var _doSomethingWithAComplexFunctionSignature: (Int, String, Bool, (Int, String) -> Void) async throws -> String = { _, _, _, _ in
                    unimplemented()
                }
                public func doSomethingWithAComplexFunctionSignature(
                         _ a: Int,
                         _ b: String,
                         c: Bool,
                         d: (Int, String) -> Void
                     ) async throws -> String {
                    try await _doSomethingWithAComplexFunctionSignature(a, b,
                            c,
                            d)
                }
            }

            extension MyProtocol where Self == MyProtocolMock {
                            public static var mock: MyProtocolMock {
                                    MyProtocolMock()
                            }
                }
            """
        }
    }
}
