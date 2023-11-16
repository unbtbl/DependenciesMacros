/// A macro that expands to a `DependencyKey` and accessors for a given property, intended to be
/// used within an extension to `DependencyValues`.
///
/// Example usage:
///
/// ```swift
/// extension DependencyValues {
///    @DependencyKey(
///       liveValue: Foo(),
///       testValue: MockFoo(),
///    )
///    public var foo: Foo
/// }
/// ````
///
/// Due to constraints in the names that can be defined in a macro, without resorting to `arbitrary`
/// (which has it's own problems), the generated dependency key will be the name of the propperty
/// prefixed with `DependencyKeyFor_`. For example, `@DependencyKey var foo: Foo` will generate
/// `DependencyKeyFor_foo` (within the namespace of the `foo` variable).
@attached(peer, names: prefixed(DependencyKeyFor_))
@attached(accessor)
public macro DependencyKey<T>(
    liveValue: T? = nil,
    testValue: T
) = #externalMacro(module: "UnbeatableDependenciesMacrosPlugin", type: "DependencyKeyMacro")

/// Used to express dependency keys with key paths.
@dynamicMemberLookup
public struct _KeyPathTarget {
    private init() {}

    public subscript(dynamicMember _: String) -> Never {
        fatalError("This subscript should never be called")
    }
}

@freestanding(declaration, names: arbitrary)
public macro dependencyKey<T>(
    _ name: KeyPath<_KeyPathTarget, Never>,
    liveValue: T? = nil,
    testValue: T,
    previewValue: T? = nil
) = #externalMacro(module: "UnbeatableDependenciesMacrosPlugin", type: "DependencyKeyMacro")
