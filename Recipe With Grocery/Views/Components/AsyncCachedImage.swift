import SwiftUI

struct AsyncCachedImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let url else { return }

        if let cached = ImageCacheService.shared.image(for: url) {
            await MainActor.run { uiImage = cached }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return }
            ImageCacheService.shared.store(image, for: url)
            await MainActor.run {
                uiImage = image
            }
        } catch {
            return
        }
    }
}
