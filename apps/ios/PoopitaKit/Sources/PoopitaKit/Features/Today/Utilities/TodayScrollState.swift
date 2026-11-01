import CoreGraphics

struct TodayScrollState: Equatable {
    struct Geometry: Equatable {
        let offset: CGFloat
        let height: CGFloat
        let contentHeight: CGFloat
    }

    var focusY: CGFloat?
    var offset: CGFloat = 0
    var height: CGFloat = 0
    private(set) var dayID: String?
    private var requestedY: CGFloat?
    private var offsetAtRequest: CGFloat?
    private var passes = 0
    private var isDone = false

    init(focusY: CGFloat? = nil, offset: CGFloat = 0, height: CGFloat = 0) {
        self.focusY = focusY
        self.offset = offset
        self.height = height
    }

    mutating func prepare(for dayID: String?) {
        guard dayID != self.dayID else { return }
        self.dayID = dayID
        focusY = nil
        restart()
    }

    mutating func restart() {
        requestedY = nil
        offsetAtRequest = nil
        passes = 0
        isDone = false
    }

    mutating func nextTarget() -> CGFloat? {
        guard !isDone, let focusY, height > 0 else { return nil }
        let delta = focusY - height / 2
        guard abs(delta) > 2, passes < 5 else {
            isDone = true
            return nil
        }
        passes += 1
        if let requestedY, let offsetAtRequest, abs(offset - offsetAtRequest) < 1 {
            return requestedY
        }
        let target = max(0, (requestedY ?? offset) + delta)
        guard target != requestedY else {
            isDone = true
            return nil
        }
        requestedY = target
        offsetAtRequest = offset
        return target
    }
}
