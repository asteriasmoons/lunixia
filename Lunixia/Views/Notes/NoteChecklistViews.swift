//
//  NoteChecklistViews.swift
//  Lunixia
//

import SwiftUI

struct NoteChecklistCircle: View {
    let isCompleted: Bool
    var size: CGFloat = 24
    var lineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isCompleted ? AnyShapeStyle(Color.clear) : AnyShapeStyle(LGradients.header),
                    lineWidth: lineWidth
                )
                .background(
                    Circle()
                        .fill(isCompleted ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(Color.clear))
            )

            if isCompleted {
                Image("checkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: size * 0.48, height: size * 0.48)
            }
        }
        .frame(width: size, height: size)
    }
}

struct NoteChecklistDisplay: View {
    let items: [NoteChecklistItem]
    let font: NoteFontOption
    var textColor: Color = .white
    var circleSize: CGFloat = 22
    var textSize: CGFloat = 15
    var lineLimit: Int? = nil
    var rowSpacing: CGFloat = 9

    var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 9) {
                    NoteChecklistCircle(isCompleted: item.isCompleted, size: circleSize)
                        .padding(.top, 1)

                    Text(item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Checklist item" : item.title)
                        .font(font.font(size: textSize))
                        .foregroundStyle(textColor)
                        .strikethrough(item.isCompleted, color: textColor.opacity(0.72))
                        .lineSpacing(2)
                        .lineLimit(lineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct NoteChecklistInteractiveDisplay: View {
    let items: [NoteChecklistItem]
    let font: NoteFontOption
    var textColor: Color = .white
    var circleSize: CGFloat = 22
    var textSize: CGFloat = 15
    var lineLimit: Int? = nil
    var rowSpacing: CGFloat = 9
    var onToggle: (NoteChecklistItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 9) {
                    Button {
                        onToggle(item)
                    } label: {
                        NoteChecklistCircle(isCompleted: item.isCompleted, size: circleSize)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.isCompleted ? "Mark item incomplete" : "Mark item complete")

                    Text(item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Checklist item" : item.title)
                        .font(font.font(size: textSize))
                        .foregroundStyle(textColor)
                        .strikethrough(item.isCompleted, color: textColor.opacity(0.72))
                        .lineSpacing(2)
                        .lineLimit(lineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct NoteChecklistEditor: View {
    @Binding var items: [NoteChecklistItem]
    let font: NoteFontOption
    var fontSize: CGFloat = 15
    @FocusState private var focusedChecklistItemID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Checklist")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    items.append(NoteChecklistItem())
                } label: {
                    Image("addwavy")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.10))
                                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add checklist item")
            }

            if items.isEmpty {
                Text("No checklist items yet.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach($items) { $item in
                        HStack(alignment: .center, spacing: 9) {
                            Button {
                                item.isCompleted.toggle()
                            } label: {
                                NoteChecklistCircle(isCompleted: item.isCompleted, size: 24)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.isCompleted ? "Mark item incomplete" : "Mark item complete")

                            TextField("Checklist item", text: $item.title, axis: .vertical)
                                .font(font.font(size: fontSize))
                                .foregroundStyle(.white)
                                .opacity(item.isCompleted ? 0.70 : 1)
                                .lineLimit(1...3)
                                .focused($focusedChecklistItemID, equals: item.id)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 9)
                                .frame(minHeight: 42, alignment: .center)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.10))
                                )
                                .overlay(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.20), lineWidth: 1)

                                        if item.isCompleted {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.72))
                                                .frame(height: 1)
                                                .padding(.horizontal, 10)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )

                            Button {
                                items.removeAll { $0.id == item.id }
                            } label: {
                                Image("xmarkwavy")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 13, height: 13)
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.10))
                                            .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove checklist item")
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedChecklistItemID != nil {
                    Spacer()
                    Button {
                        focusedChecklistItemID = nil
                    } label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(LGradients.header, in: Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
