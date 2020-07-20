import Clibgit2

/**
 A branch, note, or tag.

 - SeeAlso: `Branch`
 - SeeAlso: `Note`
 - SeeAlso: `Tag`
 */
public class Reference/*: Identifiable */ {
    private(set) var pointer: OpaquePointer!

    private var managed: Bool = false

    required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        guard managed else { return }
        git_reference_free(pointer)
    }

    // MARK: -

    /// Normalization options for reference lookup.
    public enum Format {
        /// No particular normalization.
        case normal

        /**
         Control whether one-level refnames are accepted
         (i.e., refnames that do not contain multiple `/`-separated components).

         Those are expected to be written only using
         uppercase letters and underscore (`FETCH_HEAD`, ...)
         */
        case allowOneLevel

        /**
         Interpret the provided name as a reference pattern for a refspec
         (as used with remote repositories).

         If this option is enabled,
         the name is allowed to contain a single `*` (<star>)
         in place of a one full pathname component
         (e.g., `foo/<star>/bar` but not `foo/bar<star>`).
         */
        case refspecPattern

        /**
         Interpret the name as part of a refspec in shorthand form
         so the `ONELEVEL` naming rules aren't enforced
         and 'master' becomes a valid name.
         */
        case refspecShorthand

        var rawValue: git_reference_format_t {
            switch self {
            case .normal:
                return GIT_REFERENCE_FORMAT_NORMAL
            case .allowOneLevel:
                return GIT_REFERENCE_FORMAT_ALLOW_ONELEVEL
            case .refspecPattern:
                return GIT_REFERENCE_FORMAT_REFSPEC_PATTERN
            case .refspecShorthand:
                return GIT_REFERENCE_FORMAT_REFSPEC_SHORTHAND
            }
        }
    }

    public static func normalize(name: String, format: Format) throws -> String {
        let length = name.underestimatedCount * 2
        let string = UnsafeMutablePointer<Int8>.allocate(capacity: length)
        try name.withCString { name in
            try wrap { git_reference_normalize_name(string, length, name, format.rawValue.rawValue) }
        }
        return String(bytesNoCopy: string, length: length, encoding: .ascii, freeWhenDone: true)!
    }

    /// The reference name.
    public var name: String {
        return String(validatingUTF8: git_reference_name(pointer))!
    }

    /// The repository containing the reference.
    public var owner: Repository {
        return Repository(git_reference_owner(pointer))
    }

    /// The target of the reference.
    var target: Object.ID? {
        switch git_reference_type(pointer) {
        case GIT_REFERENCE_SYMBOLIC:
            do {
                var resolved: OpaquePointer?
                try wrap { git_reference_resolve(&resolved, pointer) }
                defer { git_reference_free(resolved) }
                return Object.ID(rawValue: git_reference_target(resolved).pointee)
            } catch {
                return nil
            }
        default:
            return Object.ID(rawValue: git_reference_target(pointer).pointee)
        }
    }
}

// MARK: - Equatable

extension Reference: Equatable {
    public static func == (lhs: Reference, rhs: Reference) -> Bool {
        return git_reference_cmp(lhs.pointer, lhs.pointer) == 0
    }
}
