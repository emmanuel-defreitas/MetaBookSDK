import SwiftUI

/// One row of ``StructureTreeView``: label, level, and word count.
public struct StructureNodeRow: View {
    private let item: StructureOutlineItem

    public init(item: StructureOutlineItem) {
        self.item = item
    }

    public var body: some View {
        LabeledContent {
            Text(item.wordCount, format: .number)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(item.wordCount) words")
        } label: {
            Text(item.title)
                .font(.body)
            if let childSummary = item.childSummary {
                Text(childSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        StructureNodeRow(
            item: StructureOutlineItem(
                id: "p",
                title: "Chapter I",
                levelName: "chapter",
                wordCount: 1_234,
                childSummary: "12 paragraphs",
                children: nil
            ))
    }
}
