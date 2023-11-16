@_exported import func XCTestDynamicOverlay.unimplemented

/// When attached to a protocol, generates a mock implementation of that protocol.
@attached(peer, names: suffixed(Mock))
@attached(extension, names: named(mock))
public macro AutoMock() =
    #externalMacro(module: "UnbeatableDependenciesMacrosPlugin", type: "AutoMockMacro")
