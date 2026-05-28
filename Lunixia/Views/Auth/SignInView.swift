//
//  SignInView.swift
//  Lunixia
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var authUsers: [AuthUser]

    @State private var isSigningIn = false
    @State private var errorText: String?

    var body: some View {
        ZStack {
            LunixiaBackground()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 18)
                .padding(.horizontal, LSpacing.pageHorizontal)

                Spacer()

                GradientTitle(text: "Sign In")

                Text("Log in to sync your data across devices.")
                    .font(.system(size: 14))
                    .foregroundStyle(LColors.textSecondary)

                if let errorText {
                    Text(errorText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LColors.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LSpacing.pageHorizontal)
                }

                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                        .fill(LColors.accentGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous)
                        .strokeBorder(LGradients.header, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: LSpacing.buttonRadius))
                .padding(.horizontal, LSpacing.pageHorizontal)
                .shadow(color: LColors.gradientPurple.opacity(0.35), radius: 14, x: 0, y: 8)
                .disabled(isSigningIn)

                Spacer()
            }
            .padding(.bottom, 30)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        errorText = nil
        isSigningIn = true

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                isSigningIn = false
                errorText = "Apple Sign In returned an unexpected credential."
                return
            }

            do {
                let signedInUser = try AuthService.shared.signInWithApple(
                    credential: credential,
                    existingUsers: authUsers,
                    modelContext: modelContext
                )

                appState.setSignedIn(signedInUser)
                isSigningIn = false
                dismiss()
            } catch {
                isSigningIn = false
                errorText = error.localizedDescription
            }

        case .failure(let error):
            isSigningIn = false
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                return
            }
            errorText = error.localizedDescription
        }
    }
}
