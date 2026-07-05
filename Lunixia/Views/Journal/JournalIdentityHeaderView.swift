//
//  JournalIdentityHeaderView.swift
//  Lunixia
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Preview (read-only)
// No glass card — embedded inside JournalPagedContentView which provides the card.

struct JournalIdentityHeaderView: View {
    let entry: JournalEntry
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var coverHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 16 : 16
    }

    private var resolvedTitleColor: Color {
        let hex = entry.textColorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hex.isEmpty,
              let r = UInt8(hex.prefix(2), radix: 16),
              let g = UInt8(hex.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(hex.dropFirst(4).prefix(2), radix: 16)
        else { return .white }
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image — only rendered when data exists, sits inside the card
            if let data = entry.coverImageData, let uiImage = UIImage(data: data) {
                coverImageView(uiImage)
                    .padding(.horizontal, coverHorizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 14)
            }

            // Title
            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(resolvedTitleColor)
                    .lineSpacing(2)
                    .padding(.horizontal, 20)
                    .padding(.top, entry.coverImageData == nil ? 20 : 0)
                    .padding(.bottom, 10)
            }

            // Tags
            if !entry.tags.isEmpty {
                TagFlowLayout(spacing: 6) {
                    ForEach(entry.tags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }

            // Separator before content
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
        }
    }

    @ViewBuilder
    private func coverImageView(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Image("tagsparkle")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(resolvedTitleColor)

            Text(tag)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(resolvedTitleColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(resolvedTitleColor.opacity(0.55), lineWidth: 1)
            )
    }
}
