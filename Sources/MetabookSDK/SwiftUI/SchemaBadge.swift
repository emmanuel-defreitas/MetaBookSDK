import SwiftUI

/// A compact label showing the detected schema and confidence. Confidence is conveyed by both
/// colour and an icon so it survives Differentiate Without Colour.
public struct SchemaBadge: View {
    private let schemaType: SchemaType
    private let confidence: SchemaConfidence

    public init(schemaType: SchemaType, confidence: SchemaConfidence) {
        self.schemaType = schemaType
        self.confidence = confidence
    }

    public init(structure: StructureDetail) {
        self.init(schemaType: structure.schemaType, confidence: structure.schemaConfidence)
    }

    public var body: some View {
        HStack(spacing: 6) {
            Label(schemaType.displayName, systemImage: schemaType.systemImage)
            Image(systemName: confidenceSymbol)
                .foregroundStyle(confidenceTint)
                .accessibilityLabel("\(confidence.displayName) confidence")
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary, in: .capsule)
        .accessibilityElement(children: .combine)
    }

    private var confidenceSymbol: String {
        switch confidence {
        case .high: "checkmark.seal.fill"
        case .medium: "questionmark.circle"
        case .low: "exclamationmark.triangle"
        }
    }

    private var confidenceTint: Color {
        switch confidence {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SchemaBadge(schemaType: .standardBook, confidence: .high)
        SchemaBadge(schemaType: .canonicalScripture, confidence: .medium)
        SchemaBadge(schemaType: .flat, confidence: .low)
    }
    .padding()
}
