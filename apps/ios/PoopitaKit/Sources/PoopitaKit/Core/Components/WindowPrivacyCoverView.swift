import DesignSystem
import SwiftUI
#if os(iOS)
    import UIKit
#endif

#if os(iOS)
    struct WindowPrivacyCoverView: UIViewRepresentable {
        func makeUIView(context _: Context) -> PrivacyWindowView {
            PrivacyWindowView(frame: .zero)
        }

        func updateUIView(_: PrivacyWindowView, context _: Context) {}
        static func dismantleUIView(_ uiView: PrivacyWindowView, coordinator _: Void) {
            uiView.stop()
        }
    }

    final class PrivacyWindowView: UIView {
        private var cover: UIView?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            stop()
            isUserInteractionEnabled = false
            guard let scene = window?.windowScene else { return }
            NotificationCenter.default.addObserver(
                self, selector: #selector(hideDiary), name: UIScene.willDeactivateNotification, object: scene
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(hideDiary), name: UIScene.didEnterBackgroundNotification, object: scene
            )
            NotificationCenter.default.addObserver(
                self, selector: #selector(revealDiary), name: UIScene.didActivateNotification, object: scene
            )
            if scene.activationState != .foregroundActive {
                hideDiary()
            }
        }

        func stop() {
            NotificationCenter.default.removeObserver(self, name: UIScene.willDeactivateNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
            revealDiary()
        }

        @objc private func hideDiary() {
            guard let window else { return }
            if let cover {
                window.bringSubviewToFront(cover); return
            }
            let overlay = UIView(frame: window.bounds)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.backgroundColor = UIColor(AppColor.background)
            overlay.isAccessibilityElement = true
            overlay.accessibilityLabel = "Poopita"
            overlay.accessibilityViewIsModal = true
            window.addSubview(overlay)
            cover = overlay
        }

        @objc private func revealDiary() {
            cover?.removeFromSuperview()
            cover = nil
        }
    }
#else
    struct WindowPrivacyCoverView: View {
        var body: some View {
            EmptyView()
        }
    }
#endif
