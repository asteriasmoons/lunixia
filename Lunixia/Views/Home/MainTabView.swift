//
//  MainTabView.swift
//  Lunixia
//

import SwiftUI

enum LunixiaTab: CaseIterable {
    case mood
    case health
    case journal
    case profile
    case notes
    case spiritual
    case selfCarePoints
    case premium

    static let primaryTabs: [LunixiaTab] = [
        .mood,
        .health,
        .journal,
        .profile
    ]

    static let overflowTabs: [LunixiaTab] = [
        .notes,
        .spiritual,
        .selfCarePoints,
        .premium
    ]

    var icon: String {
        switch self {
        case .journal:
            return "lovejournal"

        case .mood:
            return "xsmile"

        case .health:
            return "healthy"

        case .profile:
            return "profilewavy"

        case .notes:
            return "pin"

        case .spiritual:
            return "sparkle"

        case .selfCarePoints:
            return "heartwavy"

        case .premium:
            return "lockwavy"
        }
    }

    var title: String {
        switch self {
        case .journal:
            return "Journal"

        case .mood:
            return "Mood"

        case .health:
            return "Health"

        case .profile:
            return "Profile"

        case .notes:
            return "Notes"

        case .spiritual:
            return "Spiritual"

        case .selfCarePoints:
            return "Self-Care Points"

        case .premium:
            return "Premium"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: LunixiaTab = .mood

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
        }
        .background {
            LunixiaBackground()
                .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var selectedTabView: some View {
        switch selectedTab {
        case .journal:
            JournalTabView()

        case .mood:
            MoodTabView()

        case .health:
            HealthTabView()

        case .profile:
            NavigationStack {
                ProfileView()
            }

        case .notes:
            NotesView()

        case .spiritual:
            SpiritualView()

        case .selfCarePoints:
            SelfCarePointsView()

        case .premium:
            PremiumView()
        }
    }
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var selectedTab: LunixiaTab

    @State private var showMoreTabs = false

    private var primaryTabs: [LunixiaTab] {
        LunixiaTab.primaryTabs
    }

    private var overflowTabs: [LunixiaTab] {
        LunixiaTab.overflowTabs
    }

    private var leadingTabs: [LunixiaTab] {
        Array(primaryTabs.prefix(2))
    }

    private var trailingTabs: [LunixiaTab] {
        Array(primaryTabs.dropFirst(2))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if showMoreTabs && !overflowTabs.isEmpty {
                moreTabsMenu
                    .frame(maxWidth: 280)
                    .padding(.bottom, 116)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }

            HStack(spacing: 0) {
                ForEach(leadingTabs, id: \.self) { tab in
                    tabButton(tab)
                }

                centerAddButton

                ForEach(trailingTabs, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background {
                ZStack {
                    Capsule().fill(LColors.bg.opacity(0.95))
                    Capsule().fill(
                        LinearGradient(
                            colors: [
                                LColors.gradientBlue.opacity(0.06),
                                LColors.gradientPurple.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [
                                LColors.gradientBlue.opacity(0.95),
                                LColors.gradientPurple.opacity(0.95),
                                Color.white.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.2
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 52)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showMoreTabs)
    }

    private func tabButton(_ tab: LunixiaTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                selectedTab = tab
                showMoreTabs = false
            }
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.35),
                                    LColors.gradientPurple.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 26)
                }

                Image(tab.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(LGradients.blue)
                        : AnyShapeStyle(Color.white.opacity(0.4))
                    )
            }
            .frame(height: 26)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var centerAddButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                showMoreTabs.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(LGradients.blue)
                    .frame(width: 42, height: 42)
                    .shadow(color: LColors.gradientBlue.opacity(0.35), radius: 10, x: 0, y: 5)

                Image("addwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(LColors.bg)
                    .rotationEffect(.degrees(showMoreTabs ? 45 : 0))
            }
            .frame(height: 42)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(overflowTabs.isEmpty)
        .opacity(overflowTabs.isEmpty ? 0.45 : 1)
    }

    private var moreTabsMenu: some View {
        VStack(spacing: 6) {
            ForEach(overflowTabs, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        selectedTab = tab
                        showMoreTabs = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(tab.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(
                                selectedTab == tab
                                ? AnyShapeStyle(LGradients.blue)
                                : AnyShapeStyle(LColors.textSecondary)
                            )
                            .frame(width: 34, height: 34)
                            .background(
                                selectedTab == tab ? LColors.glassSurface2 : LColors.glassSurface,
                                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .strokeBorder(LColors.glassBorder, lineWidth: 1)
                            )

                        Text(tab.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(LColors.textPrimary)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        selectedTab == tab ? LColors.glassSurface2.opacity(0.75) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LColors.bg.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.10),
                                    LColors.gradientPurple.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    LColors.gradientBlue.opacity(0.75),
                                    LColors.gradientPurple.opacity(0.55),
                                    Color.white.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )
                )
        }
        .shadow(color: .black.opacity(0.24), radius: 22, x: 0, y: 12)
    }
}

// MARK: - Placeholder Tab View

struct PlaceholderTabView: View {
    let icon: String
    let title: String

    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(LGradients.blue)

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Coming soon")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}
