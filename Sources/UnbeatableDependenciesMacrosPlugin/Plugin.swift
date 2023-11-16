import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct UnbeatableDependenciesMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoMockMacro.self,
        DependencyKeyMacro.self,
    ]
}
