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
        "Happy","Content","Inspired","Productive","Loved","Grateful","Optimistic","Confident",
        "Motivated","Proud","Energized","Hopeful","Playful","Satisfied","Joyful","Curious",
        "Amused","Radiant","Peaceful","Uplifted","Blissful","Tender","Empowered","Liberated",
        "Adored","Enthusiastic","Vibrant","Affectionate","Courageous","Fulfilled"
    ].map { MoodEmotion(name: $0, category: .positive) }

    static let neutrals: [MoodEmotion] = [
        "Okay","Neutral","Reflective","Distracted","Confused","Calm","Thoughtful","Mellow",
        "Settled","Indifferent","Reserved","Detached","Apathetic","Composed","Nostalgic",
        "Uncertain","Withdrawn","Restless","Flat","Disconnected","Pensive","Patient",
        "Observant","Grounded","Stable","Processing","Steady","Wandering","Aware","Ordinary"
    ].map { MoodEmotion(name: $0, category: .neutral) }

    static let negatives: [MoodEmotion] = [
        "Sad","Irritated","Disappointed","Angry","Insecure","Overwhelmed","Stressed","Scared",
        "Lonely","Discouraged","Drained","Frustrated","Defeated","Anxious","Ashamed","Bitter",
        "Helpless","Guilty","Humiliated","Resentful","Abandoned","Trapped","Numb",
        "Misunderstood","Invisible","Grieving","Panicked","Rejected","Hollow","Fragile"
    ].map { MoodEmotion(name: $0, category: .negative) }
}

// MARK: - Mood Activity

struct MoodActivity: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let isCustomAsset: Bool

    static let all: [MoodActivity] = [
        MoodActivity(name: "Friends",       icon: "groupfill",              isCustomAsset: true),
        MoodActivity(name: "Family",        icon: "hearthand",              isCustomAsset: true),
        MoodActivity(name: "Community",     icon: "person.3.fill",          isCustomAsset: false),
        MoodActivity(name: "Dating",        icon: "heartcircle",            isCustomAsset: true),
        MoodActivity(name: "Texting",       icon: "chatlinesfill",          isCustomAsset: true),
        MoodActivity(name: "Calls",         icon: "phone.fill",             isCustomAsset: false),
        MoodActivity(name: "Party",         icon: "bdaycake",               isCustomAsset: true),
        MoodActivity(name: "Journaling",    icon: "lovejournal",            isCustomAsset: true),
        MoodActivity(name: "Spirituality",  icon: "sparkle",                isCustomAsset: true),
        MoodActivity(name: "Religion",      icon: "sun",                    isCustomAsset: true),
        MoodActivity(name: "Mindfulness",   icon: "sunflower",              isCustomAsset: true),
        MoodActivity(name: "Therapy",       icon: "chatsparkle",            isCustomAsset: true),
        MoodActivity(name: "Meditation",    icon: "moonzs",                 isCustomAsset: true),
        MoodActivity(name: "Hobby",         icon: "paintbrush",             isCustomAsset: true),
        MoodActivity(name: "Creative",      icon: "sparklebrush",           isCustomAsset: true),
        MoodActivity(name: "Reading",       icon: "openbook",               isCustomAsset: true),
        MoodActivity(name: "Education",     icon: "handbook",               isCustomAsset: true),
        MoodActivity(name: "Writing",       icon: "writenote",              isCustomAsset: true),
        MoodActivity(name: "Art",           icon: "paintdrop",              isCustomAsset: true),
        MoodActivity(name: "Music",         icon: "play",                   isCustomAsset: true),
        MoodActivity(name: "Work",          icon: "document",               isCustomAsset: true),
        MoodActivity(name: "Studying",      icon: "flatbook",               isCustomAsset: true),
        MoodActivity(name: "Adulting",      icon: "checkwavy",              isCustomAsset: true),
        MoodActivity(name: "Errands",       icon: "listcircle",             isCustomAsset: true),
        MoodActivity(name: "Shopping",      icon: "shopbasket",             isCustomAsset: true),
        MoodActivity(name: "Chores",        icon: "washer",                 isCustomAsset: true),
        MoodActivity(name: "Cooking",       icon: "fork.knife",             isCustomAsset: false),
        MoodActivity(name: "Baking",        icon: "cake",                   isCustomAsset: true),
        MoodActivity(name: "Fitness",       icon: "dumbbell",               isCustomAsset: true),
        MoodActivity(name: "Health",        icon: "health",                 isCustomAsset: true),
        MoodActivity(name: "Self-Care",     icon: "heartsparkle",           isCustomAsset: true),
        MoodActivity(name: "Hygiene",       icon: "shower",                 isCustomAsset: true),
        MoodActivity(name: "Exercise",      icon: "figure.run",             isCustomAsset: false),
        MoodActivity(name: "Sleep",         icon: "moonzs",                 isCustomAsset: true),
        MoodActivity(name: "Rest",          icon: "pillows",                isCustomAsset: true),
        MoodActivity(name: "Yoga",          icon: "figure.mind.and.body",   isCustomAsset: false),
        MoodActivity(name: "Swimming",      icon: "figure.pool.swim",       isCustomAsset: false),
        MoodActivity(name: "Medication",    icon: "medication",             isCustomAsset: true),
        MoodActivity(name: "Nature",        icon: "leaf.fill",              isCustomAsset: false),
        MoodActivity(name: "Outdoors",      icon: "sun",                    isCustomAsset: true),
        MoodActivity(name: "Pets",          icon: "paw",                    isCustomAsset: true),
        MoodActivity(name: "Entertainment", icon: "television",             isCustomAsset: true),
        MoodActivity(name: "Social Media",  icon: "cellphone",              isCustomAsset: true),
        MoodActivity(name: "Tech",          icon: "codewindow",             isCustomAsset: true),
        MoodActivity(name: "Gaming",        icon: "gamecontroller.fill",    isCustomAsset: false),
        MoodActivity(name: "Movies",        icon: "lovetv",                 isCustomAsset: true),
        MoodActivity(name: "Podcast",       icon: "micfill",                isCustomAsset: true),
        MoodActivity(name: "News",          icon: "linedpages",             isCustomAsset: true),
        MoodActivity(name: "Travel",        icon: "loveairballoon",         isCustomAsset: true),
        MoodActivity(name: "Driving",       icon: "car.fill",               isCustomAsset: false),
        MoodActivity(name: "Volunteering",  icon: "hearthand",              isCustomAsset: true),
        MoodActivity(name: "Dancing",       icon: "figure.dance",           isCustomAsset: false),
        MoodActivity(name: "Appointments",  icon: "calhearts",              isCustomAsset: true),
        MoodActivity(name: "Healing",       icon: "bandaidheart",           isCustomAsset: true),
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

    var sleepHours: Double = 0.0
    var exerciseMinutes: Int = 0
    var steps: Int = 0
    var meditationMinutes: Int = 0
    var waterOz: Double = 0.0

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
        self.sleepHours = 0.0
        self.exerciseMinutes = 0
        self.steps = 0
        self.meditationMinutes = 0
        self.waterOz = 0.0
    }

    var resolvedEmotions: [MoodEmotion] {
        emotionNames.compactMap { name in MoodEmotion.all.first { $0.name == name } }
    }

    var resolvedActivities: [MoodActivity] {
        activityNames.compactMap { name in MoodActivity.all.first { $0.name == name } }
    }
}
