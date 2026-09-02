import Foundation

extension StructureDetail {
    /// A small fixture for previews and tests.
    public static let preview = StructureDetail(
        schemaType: .standardBook,
        schemaConfidence: .high,
        summary: StructureSummary(
            totalTopLevelNodes: 2,
            totalParagraphs: 5,
            totalSentences: 20,
            totalWords: 400,
            avgParagraphsPerChapter: 2.5,
            avgSentencesPerParagraph: 4,
            avgWordsPerSentence: 20
        ),
        nodes: [
            .chapter(
                ChapterNode(
                    level: "chapter", index: 0, label: "Chapter I", paragraphCount: 2,
                    avgSentencesPerParagraph: 4, avgWordsPerSentence: 20, totalWords: 160, totalSentences: 8,
                    paragraphs: [
                        ParagraphNode(index: 0, sentenceCount: 4, wordCount: 80, avgWordsPerSentence: 20),
                        ParagraphNode(index: 1, sentenceCount: 4, wordCount: 80, avgWordsPerSentence: 20),
                    ]
                )),
            .chapter(
                ChapterNode(
                    level: "chapter", index: 1, label: "Chapter II", paragraphCount: 3,
                    avgSentencesPerParagraph: 4, avgWordsPerSentence: 20, totalWords: 240, totalSentences: 12,
                    paragraphs: [
                        ParagraphNode(index: 0, sentenceCount: 4, wordCount: 80, avgWordsPerSentence: 20),
                        ParagraphNode(index: 1, sentenceCount: 4, wordCount: 80, avgWordsPerSentence: 20),
                        ParagraphNode(index: 2, sentenceCount: 4, wordCount: 80, avgWordsPerSentence: 20),
                    ]
                )),
        ]
    )
}
