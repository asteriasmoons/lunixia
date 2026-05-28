//
//  ContentView.swift
//  Lunixia
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.status {
            case .checking:
                ZStack {
                    LunixiaBackground()
                        .ignoresSafeArea()
                }
                .task {
                    appState.bootstrap(modelContext: modelContext)
                }

            case .signedOut:
                SignInView()

            case .signedIn:
                MainTabView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
