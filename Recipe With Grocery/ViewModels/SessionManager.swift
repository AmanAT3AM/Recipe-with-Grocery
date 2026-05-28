import Foundation
import Supabase
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var hasResolvedInitialSession = false

    private let supabaseManager: SupabaseManager
    private var authStateTask: Task<Void, Never>?

    init(supabaseManager: SupabaseManager = .shared) {
        self.supabaseManager = supabaseManager
        self.session = supabaseManager.currentSession
        observeAuthState()
    }

    deinit {
        authStateTask?.cancel()
    }

    var isAuthenticated: Bool {
        session != nil
    }

    var displayName: String {
        session?.user.displayName ?? "Chef"
    }

    func handle(url: URL) {
        supabaseManager.handle(url: url)
    }

    func setSession(_ session: Session?) {
        self.session = session
    }

    func clearSession() {
        session = nil
    }

    func signOut() async {
        do {
            try await supabaseManager.signOut()
        } catch {
            // Keep the local session state conservative if sign-out fails.
        }

        session = nil
    }

    private func observeAuthState() {
        let authStateChanges = supabaseManager.authStateChanges

        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in authStateChanges {
                await MainActor.run {
                    if event == .initialSession {
                        self.hasResolvedInitialSession = true
                    }
                    self.session = session
                }
            }
        }
    }
}
