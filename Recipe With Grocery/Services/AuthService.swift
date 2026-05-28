import AuthenticationServices
import Foundation
import Supabase

enum AuthError: LocalizedError {
    case emptyFields
    case invalidEmail
    case weakPassword
    case passwordsDoNotMatch
    case missingIdentityToken

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Please fill in all fields."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .passwordsDoNotMatch:
            return "Passwords do not match."
        case .missingIdentityToken:
            return "Apple did not return a valid identity token."
        }
    }
}

private struct ProfilePayload: Encodable {
    let id: UUID
    let email: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
    }
}

extension AnyJSON {
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}

extension User {
    var displayName: String {
        let metadata = userMetadata
        let preferredNames = [
            metadata["full_name"]?.stringValue,
            metadata["display_name"]?.stringValue,
            metadata["name"]?.stringValue,
            metadata["username"]?.stringValue
        ]

        if let name = preferredNames.compactMap({ $0 }).first, !name.isEmpty {
            return name
        }

        if let email, let prefix = email.split(separator: "@").first, !prefix.isEmpty {
            return String(prefix)
        }

        return "Chef"
    }
}

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    private enum Configuration {
        static let supabaseURL = URL(string: "https://tljkscdnhpgybdxqsthc.supabase.co")!
        static let supabaseKey = "sb_publishable_O7s6MQMCmrk43hneLMVNFA_K52wTxwW"
        static let redirectURL = URL(string: "recipewithgrocery://auth-callback")!
    }

    let client: SupabaseClient

    private init(client: SupabaseClient? = nil) {
        if let client {
            self.client = client
            return
        }

        let options = SupabaseClientOptions(
            auth: .init(
                redirectToURL: Configuration.redirectURL,
                autoRefreshToken: true,
                emitLocalSessionAsInitialSession: true
            )
        )

        self.client = SupabaseClient(
            supabaseURL: Configuration.supabaseURL,
            supabaseKey: Configuration.supabaseKey,
            options: options
        )
    }

    var currentSession: Session? {
        client.auth.currentSession
    }

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        client.auth.authStateChanges
    }

    func handle(url: URL) {
        client.auth.handle(url)
    }

    func signOut(scope: SignOutScope = .global) async throws {
        try await client.auth.signOut(scope: scope)
    }

    func signIn(email: String, password: String) async throws -> Session {
        let normalizedEmail = try validateEmail(email)
        guard !password.isEmpty else { throw AuthError.emptyFields }
        return try await client.auth.signIn(email: normalizedEmail, password: password)
    }

    func signUp(
        displayName: String,
        email: String,
        password: String,
        confirmPassword: String
    ) async throws -> AuthResponse {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = try validateEmail(email)

        guard !trimmedName.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            throw AuthError.emptyFields
        }
        guard password == confirmPassword else {
            throw AuthError.passwordsDoNotMatch
        }
        try validatePassword(password)

        return try await client.auth.signUp(
            email: normalizedEmail,
            password: password,
            data: [
                "full_name": .string(trimmedName),
                "name": .string(trimmedName),
                "display_name": .string(trimmedName)
            ],
            redirectTo: Configuration.redirectURL
        )
    }

    func signInWithGoogle(
        launchFlow: @escaping @MainActor (URL) async throws -> URL
    ) async throws -> Session {
        try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: Configuration.redirectURL,
            launchFlow: launchFlow
        )
    }

    func signInWithApple(idToken: String, fullName: String?) async throws -> Session {
        let session = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken
            )
        )

        if let fullName, !fullName.isEmpty {
            _ = try? await client.auth.update(
                user: UserAttributes(data: [
                    "full_name": .string(fullName),
                    "display_name": .string(fullName)
                ])
            )
        }

        return session
    }

    func requestPasswordReset(email: String) async throws {
        let normalizedEmail = try validateEmail(email)
        try await client.auth.resetPasswordForEmail(
            normalizedEmail,
            redirectTo: Configuration.redirectURL
        )
    }

    func syncProfile(for user: User) async throws {
        guard let email = user.email else { return }

        let profile = ProfilePayload(
            id: user.id,
            email: email.lowercased(),
            name: user.displayName
        )

        try await client
            .from("profiles")
            .upsert(profile, onConflict: "id", returning: .minimal)
            .execute()
    }

    private func validateEmail(_ email: String) throws -> String {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else { throw AuthError.emptyFields }
        guard normalizedEmail.isValidEmail else { throw AuthError.invalidEmail }
        return normalizedEmail
    }

    private func validatePassword(_ password: String) throws {
        guard password.count >= 6 else { throw AuthError.weakPassword }
    }
}

typealias AuthService = SupabaseManager

private extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}
