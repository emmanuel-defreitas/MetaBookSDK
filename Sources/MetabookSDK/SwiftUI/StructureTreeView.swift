import SwiftUI

/// A collapsible outline of a book's structure. Drop it inside a `NavigationStack` or a sheet.
///
/// ```swift
/// if let structure = model.structure {
///     StructureTreeView(structure: structure)
/// }
/// ```
public struct StructureTreeView: View {
    private let items: [StructureOutlineItem]

    public init(structure: StructureDetail) {
        items = StructureOutlineItem.items(for: structure)
    }

    public var body: some View {
        List(items, children: \.children) { item in
            StructureNodeRow(item: item)
        }
        .accessibilityLabel("Book structure")
    }
}

#Preview {
    StructureTreeView(structure: .preview)
}
