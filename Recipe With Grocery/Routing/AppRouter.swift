import SwiftUI
import Combine

enum AppTab: Hashable {
    case discover
    case favorites
    case grocery
    case profile
}

enum AppRoute: Hashable {
    case recipeDetail(Recipe)
    case settings
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .discover
    @Published var discoverPath = NavigationPath()
    @Published var favoritesPath = NavigationPath()
    @Published var groceryPath = NavigationPath()
    @Published var isShowingSettings = false

    func push(_ route: AppRoute, on tab: AppTab = .discover) {
        switch tab {
        case .discover:
            discoverPath.append(route)
        case .favorites:
            favoritesPath.append(route)
        case .grocery:
            groceryPath.append(route)
        case .profile:
            discoverPath.append(route)
        }
    }

    func popToRoot(_ tab: AppTab) {
        switch tab {
        case .discover:
            discoverPath = NavigationPath()
        case .favorites:
            favoritesPath = NavigationPath()
        case .grocery:
            groceryPath = NavigationPath()
        case .profile:
            discoverPath = NavigationPath()
        }
    }
}
