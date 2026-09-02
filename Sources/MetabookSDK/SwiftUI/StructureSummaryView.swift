import SwiftUI

/// Whole-book aggregate counts laid out as labelled rows. Works inside a `Form`, `List`, or on its own.
public struct StructureSummaryView: View {
    private let summary: StructureSummary

    public init(summary: StructureSummary) {
        self.summary = summary
    }

    public var body: some View {
        Group {
            LabeledContent("Top-level nodes") {
                Text(summary.totalTopLevelNodes, format: .number)
            }
            if let mid = summary.totalMidLevelNodes {
                LabeledContent("Mid-level nodes") {
                    Text(mid, format: .number)
                }
            }
            LabeledContent("Paragraphs") {
                Text(summary.totalParagraphs, format: .number)
            }
            LabeledContent("Sentences") {
                Text(summary.totalSentences, format: .number)
            }
            LabeledContent("Words") {
                Text(summary.totalWords, format: .number)
            }
            LabeledContent("Paragraphs per chapter") {
                Text(summary.avgParagraphsPerChapter, format: .number.precision(.fractionLength(1)))
            }
            LabeledContent("Sentences per paragraph") {
                Text(summary.avgSentencesPerParagraph, format: .number.precision(.fractionLength(1)))
            }
            LabeledContent("Words per sentence") {
                Text(summary.avgWordsPerSentence, format: .number.precision(.fractionLength(1)))
            }
        }
        .monospacedDigit()
    }
}

#Preview {
    Form {
        Section("Summary") {
            StructureSummaryView(summary: StructureDetail.preview.summary)
        }
    }
}
