import Clibgit2

/// A note attached to a commit.
public final class Note: Reference {
    public var message: String! {
        return String(validatingUTF8: git_note_message(pointer))
    }

    public var author: Signature {
        return Signature(rawValue: git_commit_author(pointer).pointee)
    }

    public var committer: Signature {
        return Signature(rawValue: git_commit_committer(pointer).pointee)
    }

    /// The target of the reference.
    public override var target: Object? {
        try? owner.lookup(type: Object.self, with: Object.ID { oid in
            git_note_id(pointer)
        })
    }
}
