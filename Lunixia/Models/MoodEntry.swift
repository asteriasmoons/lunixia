//
//  MoodEntry.swift
//  Lunixia
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Mood Emotion Category

enum MoodEmotionCategory: String, CaseIterable {
    case positive, neutral, negative

    var bubbleColors: (Color1: String, Color2: String) {
        switch self {
        case .positive: return ("#9B6FF7", "#7d19f7")
        case .neutral:  return ("#03dbfc", "#00b8d9")
        case .negative: return ("#e019d4", "#b8009e")
        }
    }
}

// MARK: - Mood Emotion

struct MoodEmotion: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: MoodEmotionCategory

    static let all: [MoodEmotion] = positives + neutrals + negatives

    static let positives: [MoodEmotion] = [
        "happy","content","inspired","productive","loved","grateful","optimistic","confident",
        "motivated","proud","energized","hopeful","playful","satisfied","joyful","curious",
        "amused","radiant","peaceful","uplifted","blissful","tender","empowered","liberated",
        "adored","enthusiastic","vibrant","affectionate","courageous","fulfilled"
    ].map { MoodEmotion(name: $0, category: .positive) }

    static let neutrals: [MoodEmotion] = [
        "okay","neutral","reflective","distracted","confused","calm","thoughtful","mellow",
        "settled","indifferent","reserved","detached","apathetic","composed","nostalgic",
        "uncertain","withdrawn","restless","flat","disconnected","pensive","patient",
        "observant","grounded","stable","processing","steady","wandering","aware","ordinary"
    ].map { MoodEmotion(name: $0, category: .neutral) }

    static let negatives: [MoodEmotion] = [
        "sad","irritated","disappointed","angry","insecure","overwhelmed","stressed","scared",
        "lonely","discouraged","drained","frustrated","defeated","anxious","ashamed","bitter",
        "helpless","guilty","humiliated","resentful","abandoned","trapped","numb",
        "misunderstood","invisible","grieving","panicked","rejected","hollow","fragile"
    ].map { MoodEmotion(name: $0, category: .negative) }
}

// MARK: - Mood Activity

struct MoodActivity: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let isCustomAsset: Bool

    static let all: [MoodActivity] = [
        MoodActivity(name: "friends",       icon: "groupfill",              isCustomAsset: true),
        MoodActivity(name: "family",        icon: "hearthand",              isCustomAsset: true),
        MoodActivity(name: "community",     icon: "person.3.fill",          isCustomAsset: false),
        MoodActivity(name: "dating",        icon: "heartcircle",            isCustomAsset: true),
        MoodActivity(name: "texting",       icon: "chatlinesfill",          isCustomAsset: true),
        MoodActivity(name: "calls",         icon: "phone.fill",             isCustomAsset: false),
        MoodActivity(name: "party",         icon: "bdaycake",               isCustomAsset: true),
        MoodActivity(name: "journaling",    icon: "lovejournal",            isCustomAsset: true),
        MoodActivity(name: "spirituality",  icon: "sparkle",                isCustomAsset: true),
        MoodActivity(name: "religion",      icon: "sun",                    isCustomAsset: true),
        MoodActivity(name: "mindfulness",   icon: "sunflower",              isCustomAsset: true),
        MoodActivity(name: "therapy",       icon: "chatsparkle",            isCustomAsset: true),
        MoodActivity(name: "meditation",    icon: "moonzs",                 isCustomAsset: true),
        MoodActivity(name: "hobby",         icon: "paintbrush",             isCustomAsset: true),
        MoodActivity(name: "creative",      icon: "sparklebrush",           isCustomAsset: true),
        MoodActivity(name: "reading",       icon: "openbook",               isCustomAsset: true),
        MoodActivity(name: "education",     icon: "handbook",               isCustomAsset: true),
        MoodActivity(name: "writing",       icon: "writenote",              isCustomAsset: true),
        MoodActivity(name: "art",           icon: "paintdrop",              isCustomAsset: true),
        MoodActivity(name: "music",         icon: "play",                   isCustomAsset: true),
        MoodActivity(name: "work",          icon: "document",               isCustomAsset: true),
        MoodActivity(name: "studying",      icon: "flatbook",               isCustomAsset: true),
        MoodActivity(name: "adulting",      icon: "checkwavy",              isCustomAsset: true),
        MoodActivity(name: "errands",       icon: "listcircle",             isCustomAsset: true),
        MoodActivity(name: "shopping",      icon: "shopbasket",             isCustomAsset: true),
        MoodActivity(name: "chores",        icon: "washer",                 isCustomAsset: true),
        MoodActivity(name: "cooking",       icon: "fork.knife",             isCustomAsset: false),
        MoodActivity(name: "baking",        icon: "cake",                   isCustomAsset: true),
        MoodActivity(name: "fitness",       icon: "dumbbell",               isCustomAsset: true),
        MoodActivity(name: "health",        icon: "health",                 isCustomAsset: true),
        MoodActivity(name: "self-care",     icon: "heartsparkle",           isCustomAsset: true),
        MoodActivity(name: "hygiene",       icon: "shower",                 isCustomAsset: true),
        MoodActivity(name: "exercise",      icon: "figure.run",             isCustomAsset: false),
        MoodActivity(name: "sleep",         icon: "moonzs",                 isCustomAsset: true),
        MoodActivity(name: "rest",          icon: "pillows",                isCustomAsset: true),
        MoodActivity(name: "yoga",          icon: "figure.mind.and.body",   isCustomAsset: false),
        MoodActivity(name: "swimming",      icon: "figure.pool.swim",       isCustomAsset: false),
        MoodActivity(name: "medication",    icon: "medication",             isCustomAsset: true),
        MoodActivity(name: "nature",        icon: "leaf.fill",              isCustomAsset: false),
        MoodActivity(name: "outdoors",      icon: "sun",                    isCustomAsset: true),
        MoodActivity(name: "pets",          icon: "paw",                    isCustomAsset: true),
        MoodActivity(name: "entertainment", icon: "television",             isCustomAsset: true),
        MoodActivity(name: "social-media",  icon: "cellphone",              isCustomAsset: true),
        MoodActivity(name: "tech",          icon: "codewindow",             isCustomAsset: true),
        MoodActivity(name: "gaming",        icon: "gamecontroller.fill",    isCustomAsset: false),
        MoodActivity(name: "movies",        icon: "lovetv",                 isCustomAsset: true),
        MoodActivity(name: "podcast",       icon: "micfill",                isCustomAsset: true),
        MoodActivity(name: "news",          icon: "linedpages",             isCustomAsset: true),
        MoodActivity(name: "travel",        icon: "loveairballoon",         isCustomAsset: true),
        MoodActivity(name: "driving",       icon: "car.fill",               isCustomAsset: false),
        MoodActivity(name: "volunteering",  icon: "hearthand",              isCustomAsset: true),
        MoodActivity(name: "dancing",       icon: "figure.dance",           isCustomAsset: false),
        MoodActivity(name: "appointments",  icon: "calhearts",              isCustomAsset: true),
        MoodActivity(name: "healing",       icon: "bandaidheart",           isCustomAsset: true),
    ]
}

// MARK: - MoodEntry SwiftData Model

@Model
final class MoodEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date.now
    var emotionNames: [String] = [String]()
    var activityNames: [String] = [String]()
    var note: String = ""

    var weatherNote: String = ""
    var sleepHours: Double = 0.0
    var exerciseMinutes: Int = 0
    var steps: Int = 0
    var meditationMinutes: Int = 0
    var cycleNote: String = ""
    var waterOz: Double = 0.0
    var caffeineNote: String = ""

    init(
        emotions: [MoodEmotion],
        activities: [MoodActivity],
        note: String = "",
        timestamp: Date = .now
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.emotionNames = emotions.map(\.name)
        self.activityNames = activities.map(\.name)
        self.note = note
        self.weatherNote = ""
        self.sleepHours = 0.0
        self.exerciseMinutes = 0
        self.steps = 0
        self.meditationMinutes = 0
        self.cycleNote = ""
        self.waterOz = 0.0
        self.caffeineNote = ""
    }

    var resolvedEmotions: [MoodEmotion] {
        emotionNames.compactMap { name in MoodEmotion.all.first { $0.name == name } }
    }

    var resolvedActivities: [MoodActivity] {
        activityNames.compactMap { name in MoodActivity.all.first { $0.name == name } }
    }
}
