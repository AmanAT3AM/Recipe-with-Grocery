import Foundation
import Supabase
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var hasSeenOnboarding: Bool

    private let supabaseManager: SupabaseManager
    private let sessionManager: SessionManager
    private let defaults: UserDefaults
    private let onboardingKey = "app.hasSeenOnboarding"
    private var lastSyncedProfileUserID: UUID?

    init(
        supabaseManager: SupabaseManager = .shared,
        sessionManager: SessionManager,
        defaults: UserDefaults = .standard
    ) {
        self.supabaseManager = supabaseManager
        self.sessionManager = sessionManager
        self.defaults = defaults
        self.hasSeenOnboarding = defaults.bool(forKey: onboardingKey)

        Task {
            await syncCurrentSessionProfile()
        }
    }

    var session: Session? {
        sessionManager.session
    }

    var isAuthenticated: Bool {
        sessionManager.isAuthenticated
    }

    var displayName: String {
        sessionManager.displayName
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
    }

    func signIn(email: String, password: String) async {
        guard !isBusy else { return }
        beginWork()

        do {
            let session = try await supabaseManager.signIn(email: email, password: password)
            sessionManager.setSession(session)
            do {
                try await syncProfileIfNeeded(for: session)
                infoMessage = "Welcome back, \(session.user.displayName)."
            } catch {
                try? await supabaseManager.signOut(scope: .local)
                sessionManager.clearSession()
                lastSyncedProfileUserID = nil
                throw error
            }
        } catch {
            sessionManager.clearSession()
            lastSyncedProfileUserID = nil
            errorMessage = error.localizedDescription
        }

        endWork()
    }

    func signUp(
        displayName: String,
        email: String,
        password: String,
        confirmPassword: String
    ) async -> Bool {
        guard !isBusy else { return false }
        beginWork()

        do {
            let response = try await supabaseManager.signUp(
                displayName: displayName,
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )

            if let session = response.session {
                sessionManager.setSession(session)
                do {
                    try await syncProfileIfNeeded(for: session)
                    infoMessage = "Account created. You're in."
                } catch {
                    try? await supabaseManager.signOut(scope: .local)
                    sessionManager.clearSession()
                    lastSyncedProfileUserID = nil
                    throw error
                }
            } else {
                infoMessage = "Account created. Check your email to confirm your account before logging in."
            }

            endWork()
            return true
        } catch {
            sessionManager.clearSession()
            lastSyncedProfileUserID = nil
            errorMessage = error.localizedDescription
            endWork()
            return false
        }
    }

    func signInWithGoogle(
        launchFlow: @escaping @MainActor (URL) async throws -> URL
    ) async {
        guard !isBusy else { return }
        beginWork()

        do {
            let session = try await supabaseManager.signInWithGoogle(launchFlow: launchFlow)
            sessionManager.setSession(session)
            do {
                try await syncProfileIfNeeded(for: session)
                infoMessage = "Signed in with Google."
            } catch {
                try? await supabaseManager.signOut(scope: .local)
                sessionManager.clearSession()
                lastSyncedProfileUserID = nil
                throw error
            }
        } catch {
            sessionManager.clearSession()
            lastSyncedProfileUserID = nil
            errorMessage = error.localizedDescription
        }

        endWork()
    }

    func signInWithApple(idToken: String, fullName: String? = nil) async {
        guard !isBusy else { return }
        beginWork()

        do {
            let session = try await supabaseManager.signInWithApple(idToken: idToken, fullName: fullName)
            sessionManager.setSession(session)
            do {
                try await syncProfileIfNeeded(for: session)
                infoMessage = "Signed in with Apple."
            } catch {
                try? await supabaseManager.signOut(scope: .local)
                sessionManager.clearSession()
                lastSyncedProfileUserID = nil
                throw error
            }
        } catch {
            sessionManager.clearSession()
            lastSyncedProfileUserID = nil
            errorMessage = error.localizedDescription
        }

        endWork()
    }

    func requestPasswordReset(email: String) async {
        guard !isBusy else { return }
        beginWork()

        do {
            try await supabaseManager.requestPasswordReset(email: email)
            infoMessage = "Reset link sent if an account exists for that email."
        } catch {
            errorMessage = error.localizedDescription
        }

        endWork()
    }

    func signOut() async {
        guard !isBusy else { return }
        beginWork()

        do {
            try await supabaseManager.signOut()
            sessionManager.clearSession()
            lastSyncedProfileUserID = nil
            infoMessage = "Signed out successfully."
        } catch {
            errorMessage = error.localizedDescription
        }

        endWork()
    }

    func handle(url: URL) {
        supabaseManager.handle(url: url)
    }

    func clearError() {
        errorMessage = nil
    }

    func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    private func syncCurrentSessionProfile() async {
        guard let session = sessionManager.session else { return }

        do {
            try await syncProfileIfNeeded(for: session)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncProfileIfNeeded(for session: Session) async throws {
        guard lastSyncedProfileUserID != session.user.id else { return }
        try await supabaseManager.syncProfile(for: session.user)
        lastSyncedProfileUserID = session.user.id
    }

    private func beginWork() {
        errorMessage = nil
        infoMessage = nil
        isBusy = true
    }

    private func endWork() {
        isBusy = false
    }
}
