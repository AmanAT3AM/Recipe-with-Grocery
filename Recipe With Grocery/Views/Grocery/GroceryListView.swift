import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var groceryVM: GroceryViewModel
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                progressCard

                if groceryVM.groceryItems.isEmpty {
                    EmptyStateView(
                        icon: "cart",
                        title: "Your grocery list is empty",
                        message: "Add ingredients from any recipe to start building your shopping list."
                    )
                    .padding(.top, 24)
                } else {
                    grocerySections
                }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Grocery")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if groceryVM.checkedCount > 0 {
                        Button("Remove checked") {
                            groceryVM.removeCheckedItems()
                        }
                    }
                    Button(role: .destructive) {
                        groceryVM.clearAll()
                    } label: {
                        Label("Clear all", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.isShowingSettings = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
    }

    private var header: some View {
        AppHeroBanner(
            title: "Shop with confidence",
            subtitle: "Organized by pantry categories and purchase status.",
            symbol: "cart.badge.plus"
        )
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(groceryVM.checkedCount) of \(groceryVM.totalCount) items checked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if groceryVM.allChecked && groceryVM.totalCount > 0 {
                    Label("All done", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
            ProgressView(value: Double(groceryVM.checkedCount), total: Double(max(groceryVM.totalCount, 1)))
                .tint(.green)
        }
        .padding(16)
        .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private var grocerySections: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(groceryVM.groupedItems, id: \.0) { category, items in
                VStack(alignment: .leading, spacing: 8) {
                    Label(category.rawValue, systemImage: category.icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            GroceryRowView(item: item) {
                                groceryVM.toggleItem(item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    groceryVM.removeItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }

                            if item.id != items.last?.id {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct GroceryRowView: View {
    let item: GroceryItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? .green : .secondary)
                    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: item.isChecked)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.originalText)
                        .font(.subheadline.weight(.semibold))
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)

                    Text(item.recipeTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(item.formattedQuantity)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
    }
}

private extension GroceryItem {
    var formattedQuantity: String {
        let amountText = amount.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(amount)) : String(format: "%.1f", amount)
        return [amountText, unit].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
