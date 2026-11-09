import SwiftUI

public enum AppColor {
    public static let background = Color("background", bundle: .module)
    public static let surface = Color("surface", bundle: .module)
    public static let textPrimary = Color("textPrimary", bundle: .module)
    public static let textSecondary = Color("textSecondary", bundle: .module)
    public static let accent = Color("accent", bundle: .module)
    public static let destructive = Color("destructive", bundle: .module)
    public static let ink = Color("ink", bundle: .module)
    public static let onInk = Color("onInk", bundle: .module)
    public static let hairline = Color("hairline", bundle: .module)
    public static let track = Color("track", bundle: .module)
    public static let switchOn = Color("switchOn", bundle: .module)
    public static let entry = Color("entry", bundle: .module)
    public static let marker = Color("marker", bundle: .module)
}

public enum StoolSwatch {
    public static let pale = Color("stoolPale", bundle: .module)
    public static let yellow = Color("stoolYellow", bundle: .module)
    public static let tan = Color("stoolTan", bundle: .module)
    public static let orange = Color("stoolOrange", bundle: .module)
    public static let brown = Color("stoolBrown", bundle: .module)
    public static let green = Color("stoolGreen", bundle: .module)
    public static let black = Color("stoolBlack", bundle: .module)
    public static let red = Color("stoolRed", bundle: .module)
}

public enum AppIcon {
    public static let today = Image("iconToday", bundle: .module)
    public static let history = Image("iconHistory", bundle: .module)
    public static let insights = Image("iconInsights", bundle: .module)
    public static let plus = Image("iconPlus", bundle: .module)
    public static let settings = Image("iconSettings", bundle: .module)
    public static let clock = Image("iconClock", bundle: .module)
}
