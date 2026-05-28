//
// AuthUser.swift
// Lunixia
//

import Foundation
import SwiftData

enum AuthProvider: String, Codable {
    case apple = "apple"
    case email = "email"
    case google = "google"
}

@Model
final class AuthUser {
    var serverId: String?           // MongoDB user _id
    var email: String?
    var displayName: String?
    var authProviderRaw: String = AuthProvider.apple.rawValue
    var appleUserId: String?        // Apple's stable user identifier
    var googleUserId: String?       // Google's stable user identifier
    var profileImagePath: String?     // Local file URL or relative path to a saved profile image

    var createdAt: Date = Date()
    
    var authProvider: AuthProvider {
        get { AuthProvider(rawValue: authProviderRaw) ?? .apple }
        set { authProviderRaw = newValue.rawValue }
    }
    
    var isEmail: Bool { authProvider == .email }
    var isGoogle: Bool { authProvider == .google }
    var isApple: Bool { authProvider == .apple }
    
    init(
        email: String? = nil,
        displayName: String? = nil,
        authProvider: AuthProvider = .apple,
        appleUserId: String? = nil,
        googleUserId: String? = nil,
        serverId: String? = nil
    ) {
        self.email = email
        self.displayName = displayName
        self.authProviderRaw = authProvider.rawValue
        self.appleUserId = appleUserId
        self.googleUserId = googleUserId
        self.serverId = serverId
        self.createdAt = Date()
    }
}
