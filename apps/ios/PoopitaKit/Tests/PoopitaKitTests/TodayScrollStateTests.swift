import CoreGraphics
@testable import PoopitaKit
import Testing

struct TodayScrollStateTests {
    @Test func centersTheFocusAndCorrectsAnOffsetBiasOnTheNextPass() {
        var state = TodayScrollState(focusY: 900, offset: 0, height: 600)

        #expect(state.nextTarget() == 600)
        state.focusY = 340
        #expect(state.nextTarget() == 640)
        state.focusY = 300
        #expect(state.nextTarget() == nil)
    }

    @Test func waitsForLayoutAndStopsWhenItCannotScrollFurther() {
        var state = TodayScrollState(focusY: nil, offset: 0, height: 600)
        #expect(state.nextTarget() == nil)

        state.focusY = 100
        #expect(state.nextTarget() == 0)
        #expect(state.nextTarget() == nil)
    }

    @Test func aNewDayCentersAgainButTheSameDayStaysPut() {
        var state = TodayScrollState(focusY: 300, offset: 0, height: 600)
        state.prepare(for: "2026-10-31")
        #expect(state.nextTarget() == nil)

        state.focusY = 1000
        state.prepare(for: "2026-10-31")
        #expect(state.nextTarget() == nil)

        state.prepare(for: "2026-10-29")
        #expect(state.nextTarget() == 700)
    }
}
