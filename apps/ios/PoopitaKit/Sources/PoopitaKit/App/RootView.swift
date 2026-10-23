import SwiftUI

public struct RootView: View {
    private let container: AppContainer

    public init(container: AppContainer) {
        self.container = container
    }

    public var body: some View {
        HomeView(viewModel: container.makeHomeViewModel())
    }
}

#Preview {
    RootView(container: AppContainer())
}
