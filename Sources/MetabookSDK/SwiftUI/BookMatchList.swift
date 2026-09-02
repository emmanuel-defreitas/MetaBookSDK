import SwiftUI

/// Presents the candidates from an ambiguous lookup and reports the one the user picks.
public struct BookMatchList: View {
    private let matches: [BookMatch]
    private let onSelect: (BookMatch) -> Void

    public init(matches: [BookMatch], onSelect: @escaping (BookMatch) -> Void) {
        self.matches = matches
        self.onSelect = onSelect
    }

    public var body: some View {
        List(matches) { match in
            Button {
                onSelect(match)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.title)
                        .font(.body)
                    if !match.authors.isEmpty {
                        Text(match.authors.formatted(.list(type: .and)))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Analyses this edition")
        }
        .accessibilityLabel("Matching books")
    }
}

#Preview {
    BookMatchList(matches: [
        BookMatch(gutenbergId: 1342, title: "Pride and Prejudice", authors: ["Austen, Jane"]),
        BookMatch(gutenbergId: 42671, title: "Pride and Prejudice", authors: ["Austen, Jane"]),
    ]) { _ in }
}
