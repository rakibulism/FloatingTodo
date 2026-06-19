// Today — Windows desktop shell (Tauri v2).
// Wraps the shared web UI in ../../web/app and adds the platform pieces that make
// it behave like the macOS app: an always-on-top window (set in tauri.conf.json),
// auto-launch at login (autostart plugin), and an hourly re-open via Task Scheduler.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri_plugin_autostart::MacosLauncher;

fn main() {
    tauri::Builder::default()
        // Start at login, passing --auto so the app knows it was launched automatically.
        .plugin(tauri_plugin_autostart::init(
            MacosLauncher::LaunchAgent,
            Some(vec!["--auto"]),
        ))
        .plugin(tauri_plugin_updater::Builder::new().build())
        .setup(|app| {
            #[cfg(target_os = "windows")]
            ensure_hourly_task();

            // Silent auto-update on launch. No-op until the updater is configured
            // (endpoints + pubkey in tauri.conf.json) — see UPDATER.md.
            let handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                use tauri_plugin_updater::UpdaterExt;
                if let Ok(updater) = handle.updater() {
                    if let Ok(Some(update)) = updater.check().await {
                        let _ = update.download_and_install(|_, _| {}, || {}).await;
                    }
                }
            });
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running Today");
}

// Registers a Windows Scheduled Task that re-opens Today at the top of every hour,
// mirroring the macOS launchd schedule. Idempotent: schtasks /Create /F overwrites.
#[cfg(target_os = "windows")]
fn ensure_hourly_task() {
    use std::process::Command;
    if let Ok(exe) = std::env::current_exe() {
        let exe = exe.to_string_lossy().to_string();
        let _ = Command::new("schtasks")
            .args([
                "/Create", "/F",
                "/TN", "TodayHourly",
                "/SC", "HOURLY",
                "/TR", &format!("\"{}\" --auto", exe),
            ])
            .spawn();
    }
}
