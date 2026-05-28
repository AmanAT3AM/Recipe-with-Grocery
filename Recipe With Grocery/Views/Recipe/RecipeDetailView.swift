import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject private var recipeVM: RecipeViewModel
    @EnvironmentObject private var groceryVM: GroceryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: DetailTab = .ingredients
    @State private var currentRecipe: Recipe
    @State private var showAddedToGrocery = false
    @State private var isLoadingRecipe = false

    enum DetailTab: String, CaseIterable {
        case ingredients = "Ingredients"
        case instructions = "Instructions"
        case nutrition = "Info"
    }

    init(recipe: Recipe) {
        self.recipe = recipe
        _currentRecipe = State(initialValue: recipe)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 0) {
                    heroImage

                    VStack(alignment: .leading, spacing: 18) {
                        titleBlock

                        Picker("Tab", selection: $selectedTab) {
                            ForEach(DetailTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)

                        Group {
                            switch selectedTab {
                            case .ingredients:
                                ingredientsSection
                            case .instructions:
                                instructionsSection
                            case .nutrition:
                                nutritionSection
                            }
                        }
                        .animation(.easeInOut(duration: 0.22), value: selectedTab)

                        Button(action: addToGrocery) {
                            Label("Add to Grocery List", systemImage: "cart.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(20)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    recipeVM.toggleFavorite(currentRecipe)
                } label: {
                    Image(systemName: recipeVM.isFavorite(currentRecipe) ? "heart.fill" : "heart")
                        .foregroundStyle(recipeVM.isFavorite(currentRecipe) ? .red : .primary)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showAddedToGrocery {
                toast
            }
        }
        .task(id: recipe.id) {
            await loadDetail()
        }
    }

    private var heroImage: some View {
        AsyncCachedImage(url: currentRecipe.imageURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ZStack {
                Rectangle().fill(Color.recipeSurface)
                Image(systemName: "fork.knife")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 300)
        .clipped()
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(currentRecipe.title)
                .font(.title2.weight(.black))

            HStack(spacing: 10) {
                if let mins = currentRecipe.readyInMinutes {
                    statChip(icon: "clock", value: "\(mins) min")
                }
                if let servings = currentRecipe.servings {
                    statChip(icon: "person.2", value: "\(servings) servings")
                }
                if let score = currentRecipe.healthScore {
                    statChip(icon: "heart.fill", value: "\(Int(score)) health", tint: .green)
                }
            }

            if let diets = currentRecipe.diets, !diets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(diets, id: \.self) { diet in
                            Text(diet.capitalized)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
    }

    private func statChip(icon: String, value: String, tint: Color = .secondary) -> some View {
        Label(value, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.recipeSurface, in: Capsule())
            .overlay(
                Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let ingredients = currentRecipe.extendedIngredients, !ingredients.isEmpty {
                ForEach(ingredients) { ingredient in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.18))
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        Text(ingredient.displayText)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                }
            } else {
                EmptyStateView(
                    icon: "cart",
                    title: "No ingredients",
                    message: "This recipe does not include ingredient details."
                )
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let instructions = currentRecipe.analyzedInstructions, !instructions.isEmpty {
                ForEach(Array(instructions.enumerated()), id: \.offset) { _, block in
                    if !block.name.isEmpty {
                        Text(block.name)
                            .font(.headline)
                    }
                    ForEach(block.steps, id: \.number) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(step.number)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(Color.accentColor, in: Circle())
                            Text(step.step)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            } else {
                Text(currentRecipe.cleanSummary)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            }
        }
    }

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow("Cuisine", value: currentRecipe.cuisines?.joined(separator: ", ") ?? "N/A")
            infoRow("Type", value: currentRecipe.dishTypes?.joined(separator: ", ") ?? "N/A")
            infoRow("Vegan", value: currentRecipe.vegan == true ? "Yes" : "No")
            infoRow("Vegetarian", value: currentRecipe.vegetarian == true ? "Yes" : "No")
            infoRow("Gluten-free", value: currentRecipe.glutenFree == true ? "Yes" : "No")
            infoRow("Dairy-free", value: currentRecipe.dairyFree == true ? "Yes" : "No")
            infoRow("Score", value: currentRecipe.formattedScore)
        }
        .padding(16)
        .background(Color.recipeSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func addToGrocery() {
        groceryVM.addIngredients(from: currentRecipe)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            showAddedToGrocery = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                showAddedToGrocery = false
            }
        }
    }

    private var toast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Added to grocery list")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.recipeSurface, in: Capsule())
        .overlay(
            Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(radius: 10)
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func loadDetail() async {
        isLoadingRecipe = true
        defer { isLoadingRecipe = false }
        await recipeVM.selectRecipe(recipe)
        if let fetched = recipeVM.selectedRecipe {
            currentRecipe = fetched
        }
    }
}
