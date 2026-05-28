//
//  RichBlockTextView.swift
//  Lunixia
//

import SwiftUI
import UIKit

// Custom attribute key used to embed mention target IDs into the attributed string
let JournalMentionIDAttributeName = NSAttributedString.Key("JournalMentionID")

struct RichBlockTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    var isSelectable: Bool = true
    var linkTintColor: UIColor? = nil
    var onMentionTapped: ((String) -> Void)? = nil

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = isSelectable
        textView.isUserInteractionEnabled = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.adjustsFontForContentSizeCategory = true
        textView.dataDetectorTypes = []
        textView.delegate = context.coordinator

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        textView.addGestureRecognizer(tap)

        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        return textView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        let targetWidth = max(0, width)
        let fittingSize = uiView.sizeThatFits(
            CGSize(width: targetWidth, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: targetWidth, height: fittingSize.height)
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.invalidateIntrinsicContentSize()
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()

        context.coordinator.onMentionTapped = onMentionTapped

        if let linkTintColor {
            uiView.linkTextAttributes = [
                .foregroundColor: linkTintColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        } else {
            uiView.linkTextAttributes = [
                .foregroundColor: UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onMentionTapped: onMentionTapped)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var onMentionTapped: ((String) -> Void)?

        init(onMentionTapped: ((String) -> Void)?) {
            self.onMentionTapped = onMentionTapped
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended,
                  let textView = recognizer.view as? UITextView,
                  let onMentionTapped else { return }

            let point = recognizer.location(in: textView)
            var adjustedPoint = point
            adjustedPoint.x -= textView.textContainerInset.left
            adjustedPoint.y -= textView.textContainerInset.top

            let layoutManager = textView.layoutManager
            let textContainer = textView.textContainer
            layoutManager.ensureLayout(for: textContainer)

            let glyphIndex = layoutManager.glyphIndex(for: adjustedPoint, in: textContainer)
            guard glyphIndex < layoutManager.numberOfGlyphs else { return }

            let glyphRect = layoutManager.boundingRect(
                forGlyphRange: NSRange(location: glyphIndex, length: 1),
                in: textContainer
            ).insetBy(dx: -4, dy: -4)
            guard glyphRect.contains(adjustedPoint) else { return }

            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let storage = textView.textStorage
            guard charIndex < storage.length else { return }

            if let mentionID = storage.attribute(
                JournalMentionIDAttributeName,
                at: charIndex,
                effectiveRange: nil
            ) as? String {
                onMentionTapped(mentionID)
            }
        }
    }
}
