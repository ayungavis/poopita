import CoreGraphics
@testable import PoopitaKit
import Testing

struct TodayScrollStateTests {
    @Test func centersTheFocusAndCorrectsAnOffsetBiasOnTheNextPass() {
        var state = TodayScrollState(focusY: 900, offset: 0, height: 600)

        #expect(state.nextTarget() == 600)
        state.offset = 560
        state.focusY = 340
        #expect(state.nextTarget() == 640)
        state.offset = 600
        state.focusY = 300
        #expect(state.nextTarget() == nil)
    }

    @Test func aRequestTheScrollViewCouldNotApplyYetIsRetried() {
        var state = TodayScrollState(focusY: 1400, offset: 0, height: 600)

        #expect(state.nextTarget() == 1100)
        #expect(state.nextTarget() == 1100)
        state.offset = 1100
        state.focusY = 300
        #expect(state.nextTarget() == nil)
    }

    @Test func waitsForLayoutAndStopsWhenItCannotScrollFurther() {
        var state = TodayScrollState(focusY: nil, offset: 0, height: 600)
        #expect(state.nextTarget() == nil)

        state.focusY = 100
        #expect(state.nextTarget() == 0)
        state.focusY = 100
        #expect(state.nextTarget() == 0)
    }

    @Test func aNewDayForgetsTheOldFocusAndCentersOnItsOwn() {
        var state = TodayScrollState(focusY: nil, offset: 0, height: 600)
        state.prepare(for: "2026-11-01")
        state.focusY = 1000
        #expect(state.nextTarget() == 700)

        state.prepare(for: "2026-10-26")
        #expect(state.nextTarget() == nil)

        state.prepare(for: "2026-11-01")
        state.focusY = 1000
        #expect(state.nextTarget() == 700)
    }
}
