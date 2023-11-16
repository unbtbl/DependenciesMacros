import SwiftSyntax
import SwiftSyntaxBuilder

extension FunctionSignatureSyntax {
    func asFunctionType() -> FunctionTypeSyntax {
        return FunctionTypeSyntax(
            parameters: TupleTypeElementListSyntax {
                for argument in self.parameterClause.parameters {
                    TupleTypeElementSyntax(
                        type: argument.type,
                        ellipsis: argument.ellipsis
                    )
                }
            },
            effectSpecifiers: self.effectSpecifiers.map { specifiers in
                TypeEffectSpecifiersSyntax(
                    asyncSpecifier: specifiers.asyncSpecifier,
                    throwsSpecifier: specifiers.throwsSpecifier
                )
            },
            returnClause: self.returnClause
                ?? ReturnClauseSyntax(
                    type: IdentifierTypeSyntax(name: .identifier("Void"))
                )
        )
    }
}
