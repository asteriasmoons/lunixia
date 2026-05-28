//
//  AuthService.swift
//  Lunixia
//

import Foundation
import AuthenticationServices
import SwiftData

@MainActor
final class AuthService {
    static let shared = AuthService()

    private init() {}

    private enum Keys {
        static let currentAppleUserId = "auth.currentAppleUserId"
        static let currentEmail = "auth.currentEmail"
        static let currentDisplayName = "auth.currentDisplayName"
        static let currentProvider = "auth.currentProvider"
    }

    enum AuthServiceError: LocalizedError {
        case notSignedIn
        case invalidCredential
        case credentialRevoked
        case credentialNotFound
        case failedToSaveUser
        case unsupportedCredentialState

        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "No signed-in Apple account was found."
            case .invalidCredential:
                return "Apple Sign In returned an invalid credential."
            case .credentialRevoked:
                return "Your Apple Sign In session was revoked. Please sign in again."
            case .credentialNotFound:
                return "Your Apple Sign In session could not be found. Please sign in again."
            case .failedToSaveUser:
                return "Your account could not be saved locally."
            case .unsupportedCredentialState:
                return "Your Apple Sign In credential is in an unsupported state. Please sign in again."
            }
        }
    }

    // MARK: - Public API

    func signInWithApple(
        credential: ASAuthorizationAppleIDCredential,
        existingUsers: [AuthUser],
        modelContext: ModelContext
    ) throws -> AuthUser {
        let appleUserID = credential.user
        guard !appleUserID.isEmpty else {
            throw AuthServiceError.invalidCredential
        }

        let email = credential.email
        let fullNameParts = [
            credential.fullName?.givenName,
            credential.fullName?.familyName
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        let resolvedDisplayName: String? =
            fullNameParts.isEmpty ? nil : fullNameParts.joined(separator: " ")

        let matchingExisting = existingUsers.first { candidate in
            candidate.appleUserId == appleUserID
        }

        let signedInUser: AuthUser
        if let existing = matchingExisting {
            if let email { existing.email = email }
            if let resolvedDisplayName { existing.displayName = resolvedDisplayName }
            existing.appleUserId = appleUserID
            existing.authProvider = .apple
            signedInUser = existing
        } else {
            let newUser = AuthUser(
                email: email,
                displayName: resolvedDisplayName,
                authProvider: .apple,
                appleUserId: appleUserID,
                googleUserId: nil,
                serverId: nil
            )
            modelContext.insert(newUser)
            signedInUser = newUser
        }

        let duplicateUsers = existingUsers.filter {
            $0 !== signedInUser && $0.appleUserId == appleUserID
        }

        for duplicate in duplicateUsers {
            modelContext.delete(duplicate)
        }

        do {
            try modelContext.save()
        } catch {
            throw AuthServiceError.failedToSaveUser
        }

        persistSession(
            appleUserId: appleUserID,
            email: signedInUser.email,
            displayName: signedInUser.displayName
        )

        return signedInUser
    }

    func validateStoredAppleSession() async throws {
        guard let appleUserId = UserDefaults.standard.string(forKey: Keys.currentAppleUserId),
              !appleUserId.isEmpty
        else {
            throw AuthServiceError.notSignedIn
        }

        try await validateAppleCredentialState(for: appleUserId)
    }

    func fetchMeWithAutoRefresh(modelContext: ModelContext) async throws -> AuthUser {
        guard let appleUserId = UserDefaults.standard.string(forKey: Keys.currentAppleUserId),
              !appleUserId.isEmpty
        else {
            throw AuthServiceError.notSignedIn
        }

        try await validateAppleCredentialState(for: appleUserId)

        let descriptor = FetchDescriptor<AuthUser>(
            predicate: #Predicate { user in
                user.appleUserId == appleUserId
            }
        )

        if let existingUser = try modelContext.fetch(descriptor).first {
            if let remoteDisplayName = try? await UserProfileService.shared.getDisplayName(userId: appleUserId) {
                let trimmedRemoteName = remoteDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedRemoteName.isEmpty, existingUser.displayName != trimmedRemoteName {
                    existingUser.displayName = trimmedRemoteName
                    try? modelContext.save()
                }
            }

            persistSession(
                appleUserId: appleUserId,
                email: existingUser.email,
                displayName: existingUser.displayName
            )
            return existingUser
        }

        throw AuthServiceError.notSignedIn
    }

    func signOutLocal() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.currentAppleUserId)
        defaults.removeObject(forKey: Keys.currentEmail)
        defaults.removeObject(forKey: Keys.currentDisplayName)
        defaults.removeObject(forKey: Keys.currentProvider)
    }

    // MARK: - Private

    private func validateAppleCredentialState(for appleUserId: String) async throws {
        let credentialState = try await ASAuthorizationAppleIDProvider()
            .credentialState(forUserID: appleUserId)

        switch credentialState {
        case .authorized:
            return

        case .revoked:
            signOutLocal()
            throw AuthServiceError.credentialRevoked

        case .notFound, .transferred:
            signOutLocal()
            throw AuthServiceError.credentialNotFound

        @unknown default:
            signOutLocal()
            throw AuthServiceError.unsupportedCredentialState
        }
    }

    private func persistSession(
        appleUserId: String,
        email: String?,
        displayName: String?
    ) {
        let defaults = UserDefaults.standard
        defaults.set(appleUserId, forKey: Keys.currentAppleUserId)
        defaults.set(email, forKey: Keys.currentEmail)
        defaults.set(displayName, forKey: Keys.currentDisplayName)
        defaults.set("apple", forKey: Keys.currentProvider)
    }
}
