import SwiftDiagnostics
import SwiftSyntax

extension DiagnosticsError {
    init(message: String, node: some SyntaxProtocol) {
        self.init(
            diagnostics: [
                .init(
                    node: node,
                    message: SimpleDiagnosticMessage(
                        message: message,
                        diagnosticID: MessageID(
                            domain: "UnbeatableDependenciesMacros",
                            id: "error"
                        ),
                        severity: .error
                    )
                )
            ]
        )
    }
}

struct SimpleDiagnosticMessage: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
}
