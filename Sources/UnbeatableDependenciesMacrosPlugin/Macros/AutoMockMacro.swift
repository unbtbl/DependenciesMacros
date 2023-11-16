import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AutoMockMacro: PeerMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            throw DiagnosticsError(
                message: "AutoMock can only be applied to protocols",
                node: declaration
            )
        }

        let accessLevel =
            (protocolDecl.modifiers.first(where: {
                ["public", "internal", "private", "fileprivate"].contains($0.name.text)
            }) ?? .init(name: "internal")).trimmed

        let protocolName = protocolDecl.name.trimmed

        return [
            ("""
                extension \(protocolName) where Self == \(protocolName)Mock {
                    \(accessLevel) static var mock: \(protocolName)Mock {
                        \(protocolName)Mock()
                    }
                }
            """ as DeclSyntax).as(ExtensionDeclSyntax.self)!
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            throw DiagnosticsError(
                message: "AutoMock can only be applied to protocols",
                node: declaration
            )
        }

        let accessLevel =
            (protocolDecl.modifiers.first(where: {
                ["public", "internal", "private", "fileprivate"].contains($0.name.text)
            }) ?? .init(name: "internal")).trimmed

        let protocolName = protocolDecl.name.trimmed
        var functions = [FunctionDeclSyntax]()

        for member in protocolDecl.memberBlock.members {
            guard let functionDecl = member.decl.as(FunctionDeclSyntax.self) else {
                throw DiagnosticsError(
                    message: "AutoMock currently only supports functions",
                    node: member.decl
                )
            }

            functions.append(functionDecl)
        }

        let structDecl = try StructDeclSyntax(
            "\(accessLevel) struct \(protocolName)Mock: \(protocolName)"
        ) {
            "\(accessLevel) init() {}"

            for function in functions {
                let functionType = function.signature.asFunctionType()
                "\(accessLevel) var _\(function.name.trimmed): \(functionType) = \(defaultClosureForFunctionDecl(function))"

                """
                \(accessLevel) \(function.trimmed) {
                    \(implementationForFunctionDecl(function))
                }
                """
            }
        }

        return [DeclSyntax(structDecl).formatted().as(DeclSyntax.self)!]
    }

    static func defaultClosureForFunctionDecl(
        _ functionDecl: FunctionDeclSyntax
    ) -> ClosureExprSyntax {
        let parameters = ClosureShorthandParameterListSyntax {
            for _ in functionDecl.signature.parameterClause.parameters {
                // Ignore all argument labels with wildcards (_).
                ClosureShorthandParameterSyntax(name: .wildcardToken())
            }
        }

        // The signature of a closure is everything between the opening brace ('{') and the 'in' keyword
        let signature: ClosureSignatureSyntax? =
            if parameters.isEmpty {
                nil
            } else {
                ClosureSignatureSyntax(
                    parameterClause: .simpleInput(parameters),
                    inKeyword: .keyword(.in, leadingTrivia: .space, trailingTrivia: .newline)
                )
            }

        return ClosureExprSyntax(signature: signature) {
            if functionDecl.signature.returnClause == nil {
                #"XCTFail("Unimplemented")"#
            } else {
                #"unimplemented()"#
            }
        }
    }

    @CodeBlockItemListBuilder
    static func implementationForFunctionDecl(
        _ functionDecl: FunctionDeclSyntax
    ) -> CodeBlockItemListSyntax {
        let functionCall = FunctionCallExprSyntax(
            calledExpression: "_\(functionDecl.name.trimmed)" as ExprSyntax,
            leftParen: "(",
            rightParen: ")"
        ) {
            for parameter in functionDecl.signature.parameterClause.parameters {
                // Labele(identifier: parameter.firstName)
                LabeledExprSyntax(
                    expression: "\(parameter.secondName ?? parameter.firstName)" as ExprSyntax
                )
            }
        }

        let effects = functionDecl.signature.effectSpecifiers
        let isAsync = effects?.asyncSpecifier != nil
        let isThrowing = effects?.throwsSpecifier != nil

        switch (isAsync, isThrowing) {
        case (false, false):
            "\(functionCall)"
        case (true, false):
            "await \(functionCall)"
        case (false, true):
            "try \(functionCall)"
        case (true, true):
            "try await \(functionCall)"
        }
    }
}
