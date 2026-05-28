//
//  JournalEntryBackground.swift
//  Lunixia
//

import SwiftUI

struct JournalEntryBackground: View {
    let entry: JournalEntry

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                switch entry.backgroundMode {

                case .defaultLystaria:
                    LunixiaBackground()
                        .frame(width: proxy.size.width, height: proxy.size.height)

                case .solidColor:
                    solidColorBackground
                        .frame(width: proxy.size.width, height: proxy.size.height)

                case .gradient:
                    gradientBackground
                        .frame(width: proxy.size.width, height: proxy.size.height)

                    readabilityOverlay

                case .image:
                    imageBackground(size: proxy.size)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }

    // MARK: - Solid Color

    private var solidColorBackground: some View {
        Color(lunixiaHex: entry.backgroundColorHex)
            .ignoresSafeArea()
    }

    // MARK: - Gradient

    private var gradientBackground: some View {
        let start = Color(lunixiaHex: entry.backgroundGradientStartHex)
        let end = Color(lunixiaHex: entry.backgroundGradientEndHex)

        return LinearGradient(
            colors: [start, end],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Image

    private func imageBackground(size: CGSize) -> some View {
        ZStack {
            if let data = entry.backgroundImageData,
               let uiImage = UIImage(data: data) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .opacity(entry.backgroundImageOpacity)
                    .blur(radius: entry.backgroundImageBlur)
                    .ignoresSafeArea()

            } else {
                LunixiaBackground()
                    .frame(width: size.width, height: size.height)
            }

            readabilityOverlay
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    // MARK: - Overlay

    private var readabilityOverlay: some View {
        Color.black
            .opacity(entry.backgroundOverlayOpacity)
            .ignoresSafeArea()
    }
}
