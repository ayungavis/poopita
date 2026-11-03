import SwiftUI

public extension View {
    func fullScreenModal<Item: Identifiable>(
        item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View {
        #if os(iOS)
            fullScreenCover(item: item, onDismiss: onDismiss, content: content)
        #else
            sheet(item: item, onDismiss: onDismiss, content: content)
        #endif
    }

    func fullScreenModal(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> some View) -> some View {
        #if os(iOS)
            fullScreenCover(isPresented: isPresented, content: content)
        #else
            sheet(isPresented: isPresented, content: content)
        #endif
    }
}
