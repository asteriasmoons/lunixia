//
//  MoonPhaseView.swift
//  Lunixia
//

import SwiftUI

struct MoonPhaseView: View {
    let moonPhaseData: MoonPhaseData

    @State private var showMoonPhaseDetails = false

    private var currentMoonPhaseDetail: MoonPhaseDetail? {
        MoonPhaseDetailData.detail(for: moonPhaseData.phaseName)
    }

    var body: some View {
        Button {
            showMoonPhaseDetails = true
        } label: {
            MoonPhaseCard(data: moonPhaseData)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showMoonPhaseDetails) {
            if let detail = currentMoonPhaseDetail {
                MoonPhaseDetailsSheet(
                    detail: detail,
                    phaseSymbolName: moonPhaseSymbolName(for: moonPhaseData.phaseName)
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Moon Phase Card

private struct MoonPhaseCard: View {
    let data: MoonPhaseData

    private var zodiacAssetName: String {
        switch data.signName.lowercased() {
        case "aries": return "aries"
        case "taurus": return "taurus"
        case "gemini": return "gemini"
        case "cancer": return "cancer"
        case "leo": return "leo"
        case "virgo": return "virgo"
        case "libra": return "libra"
        case "scorpio": return "scorpio"
        case "sagittarius": return "sagittarius"
        case "capricorn": return "capricorn"
        case "aquarius": return "aquarius"
        case "pisces": return "pisces"
        default: return "aries"
        }
    }

    private var phaseSymbolName: String {
        moonPhaseSymbolName(for: data.phaseName)
    }

    var body: some View {
        GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: phaseSymbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LGradients.header)
                        .frame(width: 18, height: 18)

                    Text(data.phaseName)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .center, spacing: 8) {
                    Image(zodiacAssetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(LGradients.header)

                    Text(data.signName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(data.detailLine)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Details Sheet

private struct MoonPhaseDetailsSheet: View {
    let detail: MoonPhaseDetail
    let phaseSymbolName: String
    
    var body: some View {
        ZStack {
            LunixiaBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: phaseSymbolName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)

                        Text(detail.phaseName)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(LGradients.header)

                        Spacer()
                    }

                    GlassCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            moonPhaseDetailSection(title: "Vibe") {
                                Text(detail.vibe)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Divider()
                                .background(LColors.glassBorder)

                            moonPhaseDetailSection(title: "Description") {
                                Text(detail.description)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Divider()
                                .background(LColors.glassBorder)

                            moonPhaseDetailSection(title: "Rituals") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(detail.rituals, id: \.self) { ritual in
                                        HStack(alignment: .top, spacing: 10) {
                                            Circle()
                                                .fill(LColors.textSecondary)
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 6)

                                            Text(ritual)
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                .foregroundStyle(LColors.textPrimary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }

                            Divider()
                                .background(LColors.glassBorder)

                            moonPhaseDetailSection(title: "Best For") {
                                MoonBestForKeywordList(keywords: detail.bestFor)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Shared Moon Phase Pieces

private func moonPhaseSymbolName(for phaseName: String) -> String {
    switch phaseName.lowercased() {
    case "new moon":
        return "moonphase.new.moon"
    case "waxing crescent":
        return "moonphase.waxing.crescent"
    case "first quarter":
        return "moonphase.first.quarter"
    case "waxing gibbous":
        return "moonphase.waxing.gibbous"
    case "full moon":
        return "moonphase.full.moon"
    case "waning gibbous":
        return "moonphase.waning.gibbous"
    case "last quarter":
        return "moonphase.last.quarter"
    case "waning crescent":
        return "moonphase.waning.crescent"
    default:
        return "moonphase.full.moon"
    }
}

@ViewBuilder
private func moonPhaseDetailSection<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(title)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(LGradients.header)

        content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

// MARK: - Best For Keywords

private struct MoonBestForKeywordList: View {
    let keywords: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(keywords, id: \.self) { keyword in
                Text(keyword)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(LGradients.header)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(LGradients.header, lineWidth: 1)
                    )
            }
        }
    }
}
