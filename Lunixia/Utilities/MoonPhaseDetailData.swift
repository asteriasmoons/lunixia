//
//  MoonPhaseDetailData.swift
//  Lunixia
//

import Foundation

struct MoonPhaseDetail {
    let phaseName: String
    let vibe: String
    let description: String
    let rituals: [String]
    let bestFor: [String]
}

enum MoonPhaseDetailData {
    static let all: [MoonPhaseDetail] = [
        MoonPhaseDetail(
            phaseName: "New Moon",
            vibe: "Quiet beginnings in the dark, where intention takes its first breath.",
            description: "This is where you choose what kind of life you’re stepping into next. The emotional tone is quiet, inward, and open—less about doing, more about deciding. Intentions here should center on beginnings, identity shifts, and what you’re ready to invite into your world.",
            rituals: [
                "Write your intentions and place them under a candle or pillow overnight",
                "Take a cleansing shower or bath and visualize old energy dissolving away"
            ],
            bestFor: [
                "Intention Setting Magic",
                "Pathworkings and Inner Visioning",
                "Goal Setting and Planting Work"
            ]
        ),

        MoonPhaseDetail(
            phaseName: "Waxing Crescent",
            vibe: "Hope rising, like a spark catching flame.",
            description: "Here, your intentions begin to take root. The emotional tone is gentle motivation mixed with cautious hope. Focus on nurturing what you started—building belief, supporting your desires, and choosing small actions that align with where you’re going.",
            rituals: [
                "Speak your intentions out loud each morning like affirmations",
                "Light a candle daily to “grow” your desire energetically"
            ],
            bestFor: [
                "Attraction Drawing Magic",
                "Confidence and Motivation Rituals",
                "Expansion and Growth Work"
            ]
        ),

        MoonPhaseDetail(
            phaseName: "First Quarter",
            vibe: "Tension meets action—prove it to yourself.",
            description: "This phase asks you to take yourself seriously. The emotional tone can feel tense or driven, like something is pushing you forward. Intentions here should focus on commitment, overcoming hesitation, and proving to yourself that you can follow through.",
            rituals: [
                "Do one bold action toward your goal, even if it scares you",
                "Write down obstacles and burn the paper to release them"
            ],
            bestFor: [
                "Courage Strengthening Work",
                "Breaking Obstacles Rituals",
                "Momentum Building Magic",
            ]
        ),

        MoonPhaseDetail(
            phaseName: "Waxing Gibbous",
            vibe: "Refinement, focus, and quiet power building.",
            description: "Now it’s about refining your path. The emotional tone is focused and aware—you start noticing what needs adjustment. Set intentions around improvement, discipline, and aligning your actions more closely with your desired outcome.",
            rituals: [
                "Journal what’s working vs. what needs to shift",
                "Clean or organize your space to align with your goal"
            ],
            bestFor: [
                "Refinement and Alignment Rituals",
                "Discipline and Consistency",
                "Success and Skill Magic"
            ]
        ),

        MoonPhaseDetail(
            phaseName: "Full Moon",
            vibe: "Illumination, intensity, and emotional truth rising to the surface.",
            description: "This is a moment of emotional truth and energetic overflow. The tone is intense, revealing, and powerful. Intentions here shift toward release—letting go of what’s been illuminated as misaligned, and honoring what has come to fruition.",
            rituals: [
                "Charge your tools or crystals under moonlight",
                "Write what you’re releasing and safely burn or tear it"
            ],
            bestFor: [
                "Release and Banishing Magic",
                "Divination and Psychic Work",
                "Amplification and Gratitude Magic"
            ]
        ),

        MoonPhaseDetail(
            phaseName: "Waning Gibbous",
            vibe: "Gratitude softens the intensity—harvest and reflect.",
            description: "The energy softens into reflection. Emotionally, this feels thoughtful and understanding. Intentions should center on gratitude, processing experiences, and integrating what you’ve learned so it becomes part of you.",
            rituals: [
                "Write a gratitude list for what has manifested or shifted",
                "Share knowledge, advice, or kindness with someone else"
            ],
            bestFor: [
                "Growth and Self-Discovery Magic",
                "Wisdom and Teaching Work",
                "Purpose Rituals"
            ]
        ),

        MoonPhaseDetail(
            phaseName: "Last Quarter",
            vibe: "Let go, even if it’s uncomfortable.",
            description: "This phase is about conscious release and boundary-setting. The emotional tone can feel decisive, even a little detached. Focus your intentions on cutting ties, breaking patterns, and removing what no longer supports your growth.",
            rituals: [
                "Declutter a space or remove something that feels heavy",
                "Perform a cord-cutting or release visualization"
            ],
            bestFor: [
                "Boundary Setting Magic",
                "Breaking Habits and Cycles",
                "Energy Cleansing Rituals"
            ]
        ),

        MoonPhaseDetail(
            phaseName: "Waning Crescent",
            vibe: "Deep rest, surrender, and sacred stillness.",
            description: "This is your rest and reset phase. The emotional tone is slow, inward, and restorative. Intentions here are less about doing and more about allowing—healing, surrendering control, and preparing yourself energetically for the next cycle.",
            rituals: [
                "Meditate or sit in silence with no expectations",
                "Take a “do nothing” day and honor your energy"
            ],
            bestFor: [
                "Shadow and Dream Work",
                "Self-Love and Care Magic",
                "Inner Healing Rituals"
            ]
        )
    ]

    static func detail(for phaseName: String) -> MoonPhaseDetail? {
        all.first {
            $0.phaseName.lowercased() == normalizedPhaseName(phaseName).lowercased()
        }
    }

    private static func normalizedPhaseName(_ phaseName: String) -> String {
        switch phaseName.lowercased() {
        case "balsamic moon":
            return "Waning Crescent"
        default:
            return phaseName
        }
    }
}
