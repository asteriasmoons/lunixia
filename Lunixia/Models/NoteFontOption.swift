//
//  NoteFontOption.swift
//  Lunixia
//

import CoreText
import SwiftUI

enum NoteFontOption: String, CaseIterable, Identifiable, Codable {
    case system
    case rounded
    case serif
    case twoSixOnePinky
    case beautifulRainbow
    case childowEveryday
    case chunkyBear
    case foxLollipop
    case hachiMaruPop
    case inLove
    case jellyFoxHighlight
    case liveOnTheMoon
    case loveMonday
    case mightyFineDemibold
    case quirkyLoving
    case sabrinaLovely
    case soulDreams
    case sugarDonutHeart

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .twoSixOnePinky: return "261 Pinky"
        case .beautifulRainbow: return "Beautiful Rainbow"
        case .childowEveryday: return "Childow Everyday"
        case .chunkyBear: return "Chunky Bear"
        case .foxLollipop: return "Fox Lollipop"
        case .hachiMaruPop: return "Hachi Maru Pop"
        case .inLove: return "Inlove"
        case .jellyFoxHighlight: return "Jelly Fox Highlight"
        case .liveOnTheMoon: return "Live On The Moon"
        case .loveMonday: return "Love Monday"
        case .mightyFineDemibold: return "Mighty Fine Demibold"
        case .quirkyLoving: return "Quirky Loving"
        case .sabrinaLovely: return "Sabrina Lovely"
        case .soulDreams: return "Soul Dreams"
        case .sugarDonutHeart: return "Sugar Donut Heart"
        }
    }

    var postScriptName: String? {
        switch self {
        case .system, .rounded, .serif:
            return nil
        case .twoSixOnePinky:
            return "PinkyRegular"
        case .beautifulRainbow:
            return "BeautifulRainbow"
        case .childowEveryday:
            return "ChildowEveryday"
        case .chunkyBear:
            return "ChunkyBear"
        case .foxLollipop:
            return "FoxLollipopRegular"
        case .hachiMaruPop:
            return "HachiMaruPop-Regular"
        case .inLove:
            return "InLoveRegular"
        case .jellyFoxHighlight:
            return "JellyFoxHighlight"
        case .liveOnTheMoon:
            return "LiveonTheMoon"
        case .loveMonday:
            return "LoveMonday"
        case .mightyFineDemibold:
            return "ZPMightyFineDemibold"
        case .quirkyLoving:
            return "QuirkyLoving"
        case .sabrinaLovely:
            return "SabrinaLovely"
        case .soulDreams:
            return "SoulDreams"
        case .sugarDonutHeart:
            return "SugarDonutHeart"
        }
    }

    var fileName: String? {
        switch self {
        case .system, .rounded, .serif:
            return nil
        case .twoSixOnePinky:
            return "261 Pinky.otf"
        case .beautifulRainbow:
            return "Beautiful Rainbow Font by Dani 7NTypes.otf"
        case .childowEveryday:
            return "Childow Everyday.otf"
        case .chunkyBear:
            return "Chunky Bear.otf"
        case .foxLollipop:
            return "Fox Lollipop.otf"
        case .hachiMaruPop:
            return "HachiMaruPop-Regular.ttf"
        case .inLove:
            return "Inlove.otf"
        case .jellyFoxHighlight:
            return "Jelly Fox Highlight.otf"
        case .liveOnTheMoon:
            return "Live On The Moon.otf"
        case .loveMonday:
            return "Love Monday.otf"
        case .mightyFineDemibold:
            return "Mighty Fine Demibold.otf"
        case .quirkyLoving:
            return "Quirky Loving.otf"
        case .sabrinaLovely:
            return "Sabrina Lovely.otf"
        case .soulDreams:
            return "Soul Dreams.otf"
        case .sugarDonutHeart:
            return "Sugar Donut Heart.otf"
        }
    }

    static func option(for id: String) -> NoteFontOption {
        NoteFontOption(rawValue: id) ?? .system
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        NoteFontRegistrar.registerFontsIfNeeded()

        switch self {
        case .system:
            return .system(size: size, weight: weight)
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        default:
            if let postScriptName {
                return .custom(postScriptName, size: size)
            }
            return .system(size: size, weight: weight)
        }
    }
}

private enum NoteFontRegistrar {
    private static var didRegister = false

    static func registerFontsIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        for option in NoteFontOption.allCases {
            guard let fileName = option.fileName else { continue }
            let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: fileName, withExtension: nil)
            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
