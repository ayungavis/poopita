import CoreText
import DesignSystem
import Testing

struct FontRegistrationTests {
    @Test(arguments: ["DMSans-Regular", "DMSans-Medium", "DMSans-SemiBold", "InstrumentSerif-Regular"])
    func bundledFontIsRegistered(postScriptName: String) {
        AppFont.registerFonts()
        let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
        #expect(CTFontCopyPostScriptName(font) as String == postScriptName)
    }
}
