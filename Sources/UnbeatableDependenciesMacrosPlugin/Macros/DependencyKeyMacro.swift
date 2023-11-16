import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DependencyKeyMacro: PeerMacro, AccessorMacro, DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let name = try getDependencyKeyIdentifier(from: node)

        guard let dependencyType = node.genericArgumentClause?.arguments.first?.argument else {
            throw DiagnosticsError(
                message: "DependencyKey requires an explicit generic argument to specify the type",
                node: node
            )
        }

        // Next extract the test value, and optionally, the live and preview value from the macro arguments.
        guard let testValue = getArgument("testValue", from: node) else {
            throw DiagnosticsError(
                message: "DependencyKey requires a test value",
                node: node
            )
        }
        let liveValue = getArgument("liveValue", from: node)
        let previewValue = getArgument("previewValue", from: node)

        return try [
            DeclSyntax(
                generateDependencyKey(
                    for: name,
                    type: dependencyType,
                    testValue: testValue,
                    liveValue: liveValue,
                    previewValue: previewValue
                )
            ),
            DeclSyntax(
                generateDependencyValuesProperty(
                    for: name,
                    type: dependencyType
                )
            ),
        ]
    }

    /// From a macro `#dependencyKey(\.foo, ...)`, extracts `foo` as a `TokenSyntax`.
    private static func getDependencyKeyIdentifier(
        from node: some FreestandingMacroExpansionSyntax
    ) throws -> TokenSyntax {
        guard let keyPath = getArgument(nil, from: node)?.as(KeyPathExprSyntax.self) else {
            throw DiagnosticsError(
                message: "dependencyKey requires a name",
                node: node
            )
        }

        guard
            let component = keyPath.components.first?.component.as(
                KeyPathPropertyComponentSyntax.self
            ),
            keyPath.components.count == 1
        else {
            throw DiagnosticsError(
                message: "dependencyKey requires a single component key path",
                node: node
            )
        }

        return component.declName.baseName.trimmed
    }

    /// The accessors generated by the macro.
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard
            let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
        else {
            throw DiagnosticsError(
                message:
                    "DependencyAccessor can only be applied to a variable declaration (with a single binding/pattern)",
                node: declaration
            )
        }

        let dependencyKeyName: TokenSyntax = "DependencyKeyFor_\(identifier.trimmed)"

        return [
            """
            get {
                self[\(dependencyKeyName).self]
            }
            """,
            """
            set {
                self[\(dependencyKeyName).self] = newValue
            }
            """,
        ]
    }

    /// The PeerMacro implementation which generates the dependency key.
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // First make sure the declaration to which the macro is attached, is valid.
        guard
            let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
        else {
            throw DiagnosticsError(
                message:
                    "DependencyKey can only be applied to a variable declaration (with a single binding/pattern)",
                node: declaration
            )
        }

        guard let typeAnnotation = binding.typeAnnotation else {
            throw DiagnosticsError(
                message: "DependencyKey requires an explicit type annotation",
                node: declaration
            )
        }

        // Next extract the test value, and optionally, the live and preview value from the macro arguments.
        guard let testValue = getArgument("testValue", from: node) else {
            throw DiagnosticsError(
                message: "DependencyKey requires a test value",
                node: declaration
            )
        }
        let liveValue = getArgument("liveValue", from: node)
        let previewValue = getArgument("previewValue", from: node)

        return try [
            DeclSyntax(
                generateDependencyKey(
                    for: identifier,
                    type: typeAnnotation.type,
                    testValue: testValue,
                    liveValue: liveValue,
                    previewValue: previewValue
                )
            )
        ]
    }

    private static func generateDependencyKey(
        for identifier: TokenSyntax,
        type: TypeSyntax,
        testValue: ExprSyntax,
        liveValue: ExprSyntax?,
        previewValue: ExprSyntax?
    ) throws -> StructDeclSyntax {
        let dependencyKeyProtocol: TypeSyntax =
            if liveValue == nil {
                "TestDependencyKey"  // Without an explicit liveValue, we generate only a test dependency key
            } else {
                "DependencyKey"
            }
        let dependencyKeyName: TokenSyntax = "DependencyKeyFor_\(identifier.trimmed)"

        return try StructDeclSyntax(
            "public struct \(dependencyKeyName): \(dependencyKeyProtocol)"
        ) {
            "public typealias Value = \(type)"
            "public static let testValue: Value = \(testValue)"

            if let liveValue {
                "public static let liveValue: Value = \(liveValue)"
            }

            if let previewValue {
                "public static let previewValue: Value = \(previewValue)"
            }
        }
    }

    private static func generateDependencyValuesProperty(
        for identifier: TokenSyntax,
        type: TypeSyntax
    ) throws -> VariableDeclSyntax {
        let dependencyKeyName: TokenSyntax = "DependencyKeyFor_\(identifier.trimmed)"

        let decl: DeclSyntax =
            """
                public var \(identifier): \(type) {
                    get {
                        self[\(dependencyKeyName).self]
                    }
                    set {
                        self[\(dependencyKeyName).self] = newValue
                    }
                }
            """

        return decl.as(VariableDeclSyntax.self)!
    }

    /// Gets the expression of an argument from an attribute.
    /// If no name is provided, the first unnamed is returned.
    static func getArgument(_ name: String?, from node: AttributeSyntax) -> ExprSyntax? {
        guard let exprList = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        return getArgument(name, from: exprList)
    }

    static func getArgument(
        _ name: String?,
        from node: FreestandingMacroExpansionSyntax
    ) -> ExprSyntax? {
        return getArgument(name, from: node.argumentList)
    }

    static func getArgument(_ name: String?, from exprList: LabeledExprListSyntax) -> ExprSyntax? {
        for expr in exprList where expr.label?.text == name {
            // Special handling in case of string literals - we strip the quotes, so we can use them
            // to avoid circular dependencies.
            if let literal = expr.expression.as(StringLiteralExprSyntax.self),
                literal.segments.count == 1,
                let segment = literal.segments.first?.as(StringSegmentSyntax.self)
            {
                return "\(raw: segment.content.text)"
            }

            return expr.expression
        }

        return nil
    }
}
