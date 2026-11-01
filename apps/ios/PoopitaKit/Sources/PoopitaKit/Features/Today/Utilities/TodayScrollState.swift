import CoreGraphics

struct TodayScrollState {
    struct Geometry: Equatable {
        let offset: CGFloat
        let height: CGFloat
    }

    var focusY: CGFloat?
    var offset: CGFloat = 0
    var height: CGFloat = 0
    private var requestedY: CGFloat?
    private var passes = 0
    private var isDone = false

    init(focusY: CGFloat? = nil, offset: CGFloat = 0, height: CGFloat = 0) {
        self.focusY = focusY
        self.offset = offset
        self.height = height
    }

    mutating func nextTarget() -> CGFloat? {
        guard !isDone, let focusY, height > 0 else { return nil }
        let delta = focusY - height / 2
        guard abs(delta) > 2, passes < 3 else {
            isDone = true
            return nil
        }
        let target = max(0, (requestedY ?? offset) + delta)
        guard target != requestedY else {
            isDone = true
            return nil
        }
        requestedY = target
        passes += 1
        return target
    }
}
