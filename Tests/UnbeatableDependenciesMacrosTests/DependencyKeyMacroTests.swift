import MacroTesting
import UnbeatableDependenciesMacrosPlugin
import XCTest

final class DependencyKeyMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            // Set this to `true` to record all macro expansions (or use the `record` parameter
            // of `assertMacro`):
            isRecording: false,
            macros: [
                "DependencyKey": DependencyKeyMacro.self
            ]
        ) {
            super.invokeTest()
        }
    }

    func testDependencyKeyWithoutLiveValue() {
        assertMacro {
            """
            extension DependencyValues {
                @DependencyKey(testValue: 42)
                var answer: Int
            }
            """
        } expansion: {
            """
            extension DependencyValues {
                var answer: Int {
                    get {
                        self [DependencyKeyFor_answer.self]
                    }
                    set {
                        self [DependencyKeyFor_answer.self] = newValue
                    }
                }

                public struct DependencyKeyFor_answer: TestDependencyKey {
                    public typealias Value = Int
                    public static let testValue: Value = 42
                }
            }
            """
        }
    }

    func testDependencyKeyWithLiveValue() {
        assertMacro {
            """
            extension DependencyValues {
                @DependencyKey(liveValue: 123, testValue: 42)
                var answer: Int
            }
            """
        } expansion: {
            """
            extension DependencyValues {
                var answer: Int {
                    get {
                        self [DependencyKeyFor_answer.self]
                    }
                    set {
                        self [DependencyKeyFor_answer.self] = newValue
                    }
                }

                public struct DependencyKeyFor_answer: DependencyKey {
                    public typealias Value = Int
                    public static let testValue: Value = 42
                    public static let liveValue: Value = 123
                }
            }
            """
        }
    }
}
