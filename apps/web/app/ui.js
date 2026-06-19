import { store, greeting, dateLine, pendingSentence } from "./core.js";

// Runtime shell detection: the same UI runs in a browser, in the Windows Tauri
// shell, and in the Android Capacitor shell.
const isWrapped = !!(window.__TAURI__ || window.Capacitor);
const capNotif = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.LocalNotifications;

const $ = (sel) => document.querySelector(sel);
const el = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; };

const CHECK = '<svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 13l4 4L19 7"/></svg>';
const X = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>';
const LOCK = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>';

function rowEl({ id, title, done, must, onToggle, onDelete }) {
  const r = el("div", `row${done ? " done" : ""}${must ? " must" : ""}`);
  const ring = el("button", `ring${done ? " done" : ""}`, CHECK);
  ring.setAttribute("aria-label", done ? "Mark incomplete" : "Mark complete");
  ring.onclick = onToggle;
  const t = el("span", "title"); t.textContent = title;
  r.append(ring, t);
  if (onDelete) {
    const d = el("button", "del", X); d.setAttribute("aria-label", "Delete"); d.onclick = onDelete;
    r.append(d);
  }
  return r;
}

function render() {
  $(".greet").textContent = greeting();
  $(".date").textContent = dateLine();

  const list = $(".list"); list.innerHTML = "";

  if (store.must.length) {
    const lbl = el("div", "sect-label", `${LOCK} MUST DO TODAY`);
    if (store.mustPending > 0) lbl.append(el("span", "pill-count", `${store.mustPending} left`));
    list.append(lbl);
    store.must.forEach((m) => list.append(rowEl({
      id: m.id, title: m.title, done: store.mustDoneToday(m), must: true,
      onToggle: () => { store.toggleMust(m.id); render(); },
    })));
  }

  if (store.todos.length === 0 && store.must.length === 0) {
    list.append(el("div", "empty",
      '<svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><circle cx="12" cy="12" r="9"/><path d="m8.5 12 2.5 2.5 5-5"/></svg>' +
      "<p>Nothing yet.<br>Add what you don't want to forget.</p>"));
  } else if (store.todos.length) {
    if (store.must.length) list.append(el("div", "sub", "TASKS"));
    store.todos.forEach((t) => list.append(rowEl({
      id: t.id, title: t.title, done: t.done, must: false,
      onToggle: () => { store.toggleTodo(t.id); render(); },
      onDelete: () => { store.removeTodo(t.id); render(); },
    })));
  }

  $(".count").textContent = `${store.totalPending} left`;
  const clear = $(".clear");
  clear.style.display = store.hasCompleted ? "" : "none";
}

// ---------- voice ----------
function pickVoice() {
  const v = speechSynthesis.getVoices();
  const male = v.find((x) => /en/i.test(x.lang) && /(daniel|alex|fred|male|aaron|arthur|google uk english male)/i.test(x.name));
  return male || v.find((x) => /en/i.test(x.lang)) || v[0];
}
function speak() {
  if (!("speechSynthesis" in window)) return;
  const u = new SpeechSynthesisUtterance(pendingSentence());
  const voice = pickVoice(); if (voice) u.voice = voice;
  u.rate = 1.0;
  speechSynthesis.cancel(); speechSynthesis.speak(u);
}

// ---------- notifications ----------
// On Android (Capacitor) these are real OS-scheduled notifications that fire even
// when the app is closed. On the web they're best-effort while the tab is open.
let notifyTimer = null;
async function enableNotify() {
  if (capNotif) {
    const perm = await capNotif.requestPermissions();
    if (perm.display !== "granted") return false;
    await capNotif.schedule({
      notifications: [{
        id: 1, title: "Today", body: "You have tasks waiting.",
        schedule: { every: "hour", allowWhileIdle: true },
      }],
    });
    return true;
  }
  const perm = await Notification.requestPermission();
  if (perm !== "granted") return false;
  startWebNotifyLoop();
  return true;
}
async function disableNotify() {
  if (capNotif) { try { await capNotif.cancel({ notifications: [{ id: 1 }] }); } catch {} }
  clearInterval(notifyTimer);
}
function startWebNotifyLoop() {
  clearInterval(notifyTimer);
  if (!store.settings.notify || typeof Notification === "undefined" || Notification.permission !== "granted") return;
  notifyTimer = setInterval(() => {
    if (store.totalPending > 0) new Notification("Today", { body: pendingSentence(), icon: "icons/icon-192.png" });
  }, 60 * 60 * 1000);
}

// ---------- settings dialog ----------
function renderSettings() {
  const body = $("#set-must"); body.innerHTML = "";
  store.must.forEach((m) => {
    const line = el("div", "mustline", LOCK);
    const t = el("span", "t"); t.textContent = m.title; line.append(t);
    const del = el("button", "icon-btn", X); del.onclick = () => { store.removeMust(m.id); renderSettings(); render(); };
    line.append(del); body.append(line);
  });
  $("#sw-speak").classList.toggle("on", !!store.settings.speak);
  $("#sw-notify").classList.toggle("on", !!store.settings.notify);
}

// ---------- install ----------
let deferredPrompt = null;
window.addEventListener("beforeinstallprompt", (e) => {
  e.preventDefault(); deferredPrompt = e;
  if (!matchMedia("(display-mode: standalone)").matches) $(".install").classList.add("show");
});

function wire() {
  $("#add-input").addEventListener("keydown", (e) => {
    if (e.key === "Enter") { store.addTodo(e.target.value); e.target.value = ""; render(); }
  });
  $(".clear").onclick = () => { store.clearCompleted(); render(); };
  $("#speak-btn").onclick = speak;
  $("#settings-btn").onclick = () => { renderSettings(); $("#settings").showModal(); };
  $("#set-done").onclick = () => $("#settings").close();
  $("#add-must-input").addEventListener("keydown", (e) => {
    if (e.key === "Enter") { store.addMust(e.target.value); e.target.value = ""; renderSettings(); render(); }
  });
  $("#add-must-btn").onclick = () => {
    const i = $("#add-must-input"); store.addMust(i.value); i.value = ""; renderSettings(); render();
  };
  $("#sw-speak").onclick = (e) => { store.settings.speak = !store.settings.speak; store.saveSettings(); e.target.classList.toggle("on"); };
  $("#sw-notify").onclick = async (e) => {
    if (!store.settings.notify) {
      const ok = await enableNotify();
      if (!ok) return;
    } else {
      await disableNotify();
    }
    store.settings.notify = !store.settings.notify; store.saveSettings();
    e.target.classList.toggle("on", store.settings.notify);
  };
  $(".install .go").onclick = async () => {
    $(".install").classList.remove("show");
    if (deferredPrompt) { deferredPrompt.prompt(); deferredPrompt = null; }
  };
  $(".install .x").onclick = () => $(".install").classList.remove("show");
}

// ---------- boot ----------
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => navigator.serviceWorker.register("./sw.js").catch(() => {}));
}
if ("speechSynthesis" in window) speechSynthesis.onvoiceschanged = () => {};

render();
wire();
if (store.settings.notify) startWebNotifyLoop();

// Announce on launch when running as an installed/standalone/wrapped app
// (best-effort; browsers may gate audio behind a gesture, so the speaker button
// is always available).
if (store.settings.speak && (isWrapped || matchMedia("(display-mode: standalone)").matches)) {
  setTimeout(() => { try { speak(); } catch {} }, 600);
}
