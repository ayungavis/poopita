import AppIntents

struct PoopitaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogPoopIntent(),
            phrases: [
                "Log a poop in \(.applicationName)",
                "New \(.applicationName) log",
                "Log in \(.applicationName)",
            ],
            shortTitle: "intent.log.short",
            systemImageName: "plus"
        )
    }
}
