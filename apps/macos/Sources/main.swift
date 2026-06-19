import SwiftUI
import AppKit
import AVFoundation

// =====================================================================
// MARK: - Paths
// =====================================================================

enum Paths {
    static let dir: URL = {
        let fm = FileManager.default
        let d = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FloatingTodo", isDirectory: true)
        try? fm.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()
    static var todos: URL    { dir.appendingPathComponent("todos.json") }
    static var mustdo: URL   { dir.appendingPathComponent("mustdo.json") }
    static var settings: URL { dir.appendingPathComponent("settings.json") }
    static var launchAgent: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.rakib.floatingtodo.plist")
    }
}

func loadJSON<T: Decodable>(_ url: URL, as type: T.Type) -> T? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}
func saveJSON<T: Encodable>(_ value: T, to url: URL) {
    if let data = try? JSONEncoder().encode(value) {
        try? data.write(to: url, options: .atomic)
    }
}

// =====================================================================
// MARK: - Regular todos
// =====================================================================

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var done: Bool = false
    var createdAt: Date = Date()
}

final class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = [] { didSet { if !loading { saveJSON(items, to: Paths.todos) } } }
    private var loading = false

    init() {
        if let decoded = loadJSON(Paths.todos, as: [TodoItem].self) {
            loading = true; items = decoded; loading = false
        }
    }

    func add(_ title: String) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        items.insert(TodoItem(title: t), at: 0)
    }
    func toggle(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].done.toggle()
        items.sort { a, b in a.done != b.done ? !a.done : a.createdAt > b.createdAt }
    }
    func remove(_ item: TodoItem) { items.removeAll { $0.id == item.id } }
    func clearCompleted() { items.removeAll { $0.done } }

    var remaining: Int { items.filter { !$0.done }.count }
    var hasCompleted: Bool { items.contains { $0.done } }
}

// =====================================================================
// MARK: - Must-do daily tasks (reset every day)
// =====================================================================

struct MustDoTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var lastCompleted: Date? = nil

    var doneToday: Bool {
        guard let d = lastCompleted else { return false }
        return Calendar.current.isDateInToday(d)
    }
}

final class MustDoStore: ObservableObject {
    @Published var tasks: [MustDoTask] = [] { didSet { if !loading { saveJSON(tasks, to: Paths.mustdo) } } }
    private var loading = false

    init() {
        if let decoded = loadJSON(Paths.mustdo, as: [MustDoTask].self) {
            loading = true; tasks = decoded; loading = false
        }
    }

    func add(_ title: String) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        tasks.append(MustDoTask(title: t))
    }
    func toggle(_ task: MustDoTask) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[i].lastCompleted = tasks[i].doneToday ? nil : Date()
    }
    func remove(_ task: MustDoTask) { tasks.removeAll { $0.id == task.id } }

    var pendingToday: Int { tasks.filter { !$0.doneToday }.count }
}

// =====================================================================
// MARK: - Schedule settings  (drives launchd)
// =====================================================================

struct ScheduleTime: Identifiable, Codable, Equatable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var enabled: Bool = true

    var label: String {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        let date = Calendar.current.date(from: c) ?? Date()
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

struct SettingsData: Codable {
    var everyHour: Bool = true
    var times: [ScheduleTime] = []
    var speak: Bool = true
    var snoozeMinutes: Int = 30
}

final class SettingsStore: ObservableObject {
    @Published var everyHour: Bool { didSet { scheduleChanged() } }
    @Published var times: [ScheduleTime] { didSet { scheduleChanged() } }
    @Published var speak: Bool { didSet { persist() } }
    @Published var snoozeMinutes: Int { didSet { persist() } }
    private var loading = true

    init() {
        let d = loadJSON(Paths.settings, as: SettingsData.self) ?? SettingsData()
        everyHour = d.everyHour
        times = d.times
        speak = d.speak
        snoozeMinutes = d.snoozeMinutes
        loading = false
    }

    // Schedule-affecting changes save AND reload launchd; others just save.
    private func scheduleChanged() {
        guard !loading else { return }
        save(); applyToLaunchd()
    }
    private func persist() {
        guard !loading else { return }
        save()
    }
    private func save() {
        saveJSON(SettingsData(everyHour: everyHour, times: times, speak: speak, snoozeMinutes: snoozeMinutes),
                 to: Paths.settings)
    }

    func addTime(hour: Int, minute: Int) {
        times.append(ScheduleTime(hour: hour, minute: minute))
        times.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }
    func removeTime(_ t: ScheduleTime) { times.removeAll { $0.id == t.id } }
    func toggleTime(_ t: ScheduleTime) {
        guard let i = times.firstIndex(where: { $0.id == t.id }) else { return }
        times[i].enabled.toggle()
    }

    // Regenerate the LaunchAgent plist and reload it.
    func applyToLaunchd() {
        let appPath = Bundle.main.bundlePath
        var intervals = ""
        if everyHour {
            intervals += "        <dict><key>Minute</key><integer>0</integer></dict>\n"
        }
        for t in times where t.enabled {
            intervals += "        <dict><key>Hour</key><integer>\(t.hour)</integer><key>Minute</key><integer>\(t.minute)</integer></dict>\n"
        }
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.rakib.floatingtodo</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/open</string>
                <string>-a</string>
                <string>\(appPath)</string>
                <string>--args</string>
                <string>--auto</string>
            </array>
            <key>StartCalendarInterval</key>
            <array>
        \(intervals)    </array>
            <key>RunAtLoad</key>
            <false/>
        </dict>
        </plist>
        """
        try? plist.write(to: Paths.launchAgent, atomically: true, encoding: .utf8)
        launchctl(["unload", Paths.launchAgent.path])
        launchctl(["load", Paths.launchAgent.path])
    }

    private func launchctl(_ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run(); p.waitUntilExit()
    }
}

// =====================================================================
// MARK: - Voice
// =====================================================================

final class Speaker {
    private let synth = AVSpeechSynthesizer()

    private func maleVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let v = voices.first(where: { $0.language.hasPrefix("en") && $0.gender == .male }) { return v }
        if let v = voices.first(where: { $0.gender == .male }) { return v }
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    func announce(regularPending: Int, mustPending: Int) {
        let total = regularPending + mustPending
        var text: String
        if total == 0 {
            text = "Nice. You're all caught up, nothing pending."
        } else {
            let taskWord = total == 1 ? "task" : "tasks"
            text = "You have \(total) pending \(taskWord)."
            if mustPending > 0 {
                let m = mustPending == 1 ? "is a must-do" : "are must-do"
                text += " \(mustPending) of them \(m)."
            }
        }
        let u = AVSpeechUtterance(string: text)
        u.voice = maleVoice()
        u.rate = 0.5
        u.preUtteranceDelay = 0.4
        synth.speak(u)
    }
}

// =====================================================================
// MARK: - Main view
// =====================================================================

struct ContentView: View {
    @ObservedObject var store: TodoStore
    @ObservedObject var mustDo: MustDoStore
    @ObservedObject var settings: SettingsStore

    @State private var newTitle = ""
    @State private var showSettings = false
    @FocusState private var inputFocused: Bool

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Late night"
        }
    }
    private var dateLine: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            inputRow
            Divider().opacity(0.4)
            content
            footer
        }
        .frame(minWidth: 380, minHeight: 480)
        .background(VisualEffectBackground())
        .onAppear { inputFocused = true }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings, mustDo: mustDo)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(.system(size: 22, weight: .bold, design: .rounded))
                Text(dateLine).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.system(size: 15)).foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings — schedule & must-do tasks")
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 14)
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(.tint)
            TextField("Add a task…", text: $newTitle)
                .textFieldStyle(.plain).font(.system(size: 14))
                .focused($inputFocused).onSubmit(addCurrent)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Color.primary.opacity(0.06)))
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if !mustDo.tasks.isEmpty { mustDoSection }
                if store.items.isEmpty && mustDo.tasks.isEmpty {
                    emptyState
                } else {
                    ForEach(store.items) { item in
                        TodoRow(title: item.title, done: item.done, locked: false,
                                toggle: { store.toggle(item) }, remove: { store.remove(item) })
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .frame(maxHeight: .infinity)
    }

    private var mustDoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
                Text("MUST DO TODAY").font(.system(size: 11, weight: .heavy)).tracking(0.6)
                if mustDo.pendingToday > 0 {
                    Text("\(mustDo.pendingToday) left")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.red.opacity(0.18)))
                        .foregroundStyle(.red)
                }
            }
            .foregroundStyle(mustDo.pendingToday > 0 ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
            .padding(.horizontal, 12).padding(.top, 2)

            ForEach(mustDo.tasks) { task in
                TodoRow(title: task.title, done: task.doneToday, locked: true,
                        toggle: { mustDo.toggle(task) }, remove: nil)
            }
            if !store.items.isEmpty {
                Divider().opacity(0.3).padding(.vertical, 4)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle").font(.system(size: 34, weight: .light)).foregroundStyle(.secondary)
            Text("Nothing yet.\nAdd what you don't want to forget.")
                .multilineTextAlignment(.center).font(.system(size: 13)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }

    private var footer: some View {
        HStack {
            Text("\(store.remaining + mustDo.pendingToday) left")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            Spacer()
            if store.hasCompleted {
                Button("Clear completed", action: store.clearCompleted)
                    .buttonStyle(.plain).font(.system(size: 12, weight: .medium)).foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func addCurrent() {
        store.add(newTitle); newTitle = ""; inputFocused = true
    }
}

struct TodoRow: View {
    let title: String
    let done: Bool
    let locked: Bool
    let toggle: () -> Void
    let remove: (() -> Void)?
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 11) {
            Button(action: toggle) {
                Image(systemName: done ? "checkmark.circle.fill" : (locked ? "lock.circle" : "circle"))
                    .font(.system(size: 18))
                    .foregroundStyle(done ? AnyShapeStyle(.tint)
                                          : (locked ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary)))
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: 14))
                .strikethrough(done, color: .secondary)
                .foregroundStyle(done ? .secondary : .primary)
                .lineLimit(3)

            Spacer(minLength: 4)

            if hovering, let remove {
                Button(action: remove) {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain).help("Delete")
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(locked && !done ? Color.red.opacity(0.06)
                  : (hovering ? Color.primary.opacity(0.05) : .clear)))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

// =====================================================================
// MARK: - Settings
// =====================================================================

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var mustDo: MustDoStore
    @Environment(\.dismiss) private var dismiss

    @State private var newTime = Date()
    @State private var newMust = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Settings").font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    scheduleSection
                    mustDoSection
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
        .frame(width: 420, height: 520)
        .background(VisualEffectBackground())
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("AUTO-OPEN SCHEDULE")

            Toggle(isOn: $settings.everyHour) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Every hour, on the hour").font(.system(size: 13, weight: .medium))
                    Text("Pops up at the top of every hour").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: $settings.speak) {
                Text("Announce pending tasks with voice").font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.switch)

            if !settings.times.isEmpty {
                Text("Custom times").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).padding(.top, 4)
            }
            ForEach(settings.times) { t in
                HStack(spacing: 10) {
                    Toggle("", isOn: Binding(
                        get: { t.enabled },
                        set: { _ in settings.toggleTime(t) }
                    )).toggleStyle(.switch).labelsHidden()
                    Text(t.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(t.enabled ? .primary : .secondary)
                    Spacer()
                    Button {
                        settings.removeTime(t)
                    } label: { Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(.secondary) }
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
            }

            HStack(spacing: 10) {
                DatePicker("", selection: $newTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.field).labelsHidden()
                Button {
                    let c = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                    settings.addTime(hour: c.hour ?? 9, minute: c.minute ?? 0)
                } label: {
                    Label("Add time", systemImage: "plus").font(.system(size: 12, weight: .medium))
                }
            }
            .padding(.top, 2)
        }
    }

    private var mustDoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("MUST-DO EVERY DAY")
            Text("These reset every morning and must be completed each day.")
                .font(.system(size: 11)).foregroundStyle(.secondary)

            ForEach(mustDo.tasks) { task in
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(.red)
                    Text(task.title).font(.system(size: 13, weight: .medium))
                    Spacer()
                    Button { mustDo.remove(task) } label: {
                        Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.06)))
            }

            HStack(spacing: 10) {
                TextField("New daily must-do…", text: $newMust)
                    .textFieldStyle(.roundedBorder).font(.system(size: 13))
                    .onSubmit(addMust)
                Button(action: addMust) {
                    Label("Add", systemImage: "plus").font(.system(size: 12, weight: .medium))
                }
            }

            HStack(spacing: 8) {
                Text("Closing snoozes for").font(.system(size: 13, weight: .medium))
                Text("\(settings.snoozeMinutes) min").font(.system(size: 13, weight: .semibold)).monospacedDigit()
                Stepper("", value: $settings.snoozeMinutes, in: 5...120, step: 5).labelsHidden()
            }
            .padding(.top, 2)
        }
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s).font(.system(size: 11, weight: .heavy)).tracking(0.6).foregroundStyle(.secondary)
    }
    private func addMust() {
        mustDo.add(newMust); newMust = ""
    }
}

// =====================================================================
// MARK: - Background helper
// =====================================================================

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .underWindowBackground
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// =====================================================================
// MARK: - App lifecycle
// =====================================================================

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    let store = TodoStore()
    let mustDo = MustDoStore()
    let settings = SettingsStore()
    let speaker = Speaker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Standard menu bar — without it, ⌘W / ⌘M / ⌘Q and text-edit shortcuts do nothing.
        buildMenu()

        // Keep the launchd schedule in sync with current settings every launch.
        settings.applyToLaunchd()

        let root = ContentView(store: store, mustDo: mustDo, settings: settings)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 580),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.title = "Today"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: root)
        window.center()
        window.delegate = self

        // Always on top — overlay everything, including other apps' full-screen.
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Speak only when launched by the schedule (--auto) and voice is enabled.
        if settings.speak && CommandLine.arguments.contains("--auto") {
            speaker.announce(regularPending: store.remaining, mustPending: mustDo.pendingToday)
        }
    }

    private func buildMenu() {
        let appName = "Today"
        let mainMenu = NSMenu()

        // App menu
        let appItem = NSMenuItem(); mainMenu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About \(appName)",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide \(appName)",
                        action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others",
                        action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit \(appName)",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // Edit menu (enables Cut/Copy/Paste/Select All/Undo in text fields)
        let editItem = NSMenuItem(); mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit"); editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: Selector(("cut:")), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: Selector(("copy:")), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: Selector(("paste:")), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: Selector(("selectAll:")), keyEquivalent: "a")

        // Window menu (⌘M minimize, ⌘W close)
        let windowItem = NSMenuItem(); mainMenu.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window"); windowItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Minimize",
                           action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom",
                           action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Close",
                           action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
        return true
    }

    // Must-do tasks can't be dismissed for good: closing while any remain just
    // snoozes the app for 30 minutes, then it reappears. (⌘M minimize is always
    // allowed and doesn't trigger this.) When all must-do's are done, closing is
    // a normal close until the next scheduled time.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if mustDo.pendingToday > 0 {
            scheduleSnoozeReopen(minutes: settings.snoozeMinutes)
        }
        return true
    }

    // Spawn a detached helper that re-opens the app after a delay. It survives
    // this app quitting (reparented to launchd), so the window comes back.
    private func scheduleSnoozeReopen(minutes: Int) {
        let appPath = Bundle.main.bundlePath
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", "sleep \(minutes * 60); /usr/bin/open -a \"\(appPath)\" --args --auto"]
        try? p.run()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
