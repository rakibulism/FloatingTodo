// Shared todo + must-do data model. Used by the web PWA and (via the wrappers)
// by the Windows (Tauri) and Android (Capacitor) shells. No dependencies.

const KEYS = { todos: "ft.todos", must: "ft.mustdo", settings: "ft.settings" };

function load(key, fallback) {
  try { const v = JSON.parse(localStorage.getItem(key)); return v ?? fallback; }
  catch { return fallback; }
}
function persist(key, value) { localStorage.setItem(key, JSON.stringify(value)); }
function uid() { return crypto.randomUUID ? crypto.randomUUID() : String(Date.now()) + Math.random(); }
function isToday(ts) {
  if (!ts) return false;
  return new Date(ts).toDateString() === new Date().toDateString();
}

export const store = {
  todos: load(KEYS.todos, []),
  must: load(KEYS.must, []),
  settings: load(KEYS.settings, { speak: true, notify: false }),

  saveTodos() { persist(KEYS.todos, this.todos); },
  saveMust() { persist(KEYS.must, this.must); },
  saveSettings() { persist(KEYS.settings, this.settings); },

  // ---- regular todos ----
  addTodo(title) {
    title = title.trim(); if (!title) return;
    this.todos.unshift({ id: uid(), title, done: false, createdAt: Date.now() });
    this.saveTodos();
  },
  toggleTodo(id) {
    const t = this.todos.find((x) => x.id === id); if (!t) return;
    t.done = !t.done;
    this.todos.sort((a, b) => (a.done !== b.done ? (a.done ? 1 : -1) : b.createdAt - a.createdAt));
    this.saveTodos();
  },
  removeTodo(id) { this.todos = this.todos.filter((x) => x.id !== id); this.saveTodos(); },
  clearCompleted() { this.todos = this.todos.filter((x) => !x.done); this.saveTodos(); },
  get remaining() { return this.todos.filter((t) => !t.done).length; },
  get hasCompleted() { return this.todos.some((t) => t.done); },

  // ---- must-do daily (reset each calendar day) ----
  addMust(title) {
    title = title.trim(); if (!title) return;
    this.must.push({ id: uid(), title, lastCompleted: null });
    this.saveMust();
  },
  toggleMust(id) {
    const t = this.must.find((x) => x.id === id); if (!t) return;
    t.lastCompleted = isToday(t.lastCompleted) ? null : Date.now();
    this.saveMust();
  },
  removeMust(id) { this.must = this.must.filter((x) => x.id !== id); this.saveMust(); },
  mustDoneToday(t) { return isToday(t.lastCompleted); },
  get mustPending() { return this.must.filter((t) => !isToday(t.lastCompleted)).length; },

  // ---- derived ----
  get totalPending() { return this.remaining + this.mustPending; },
};

export function greeting(d = new Date()) {
  const h = d.getHours();
  if (h >= 5 && h < 12) return "Good morning";
  if (h >= 12 && h < 17) return "Good afternoon";
  if (h >= 17 && h < 22) return "Good evening";
  return "Late night";
}

export function dateLine(d = new Date()) {
  return d.toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" });
}

export function pendingSentence() {
  const total = store.totalPending, must = store.mustPending;
  if (total === 0) return "Nice. You're all caught up, nothing pending.";
  let s = `You have ${total} pending task${total === 1 ? "" : "s"}.`;
  if (must > 0) s += ` ${must} of them ${must === 1 ? "is a must-do" : "are must-do"}.`;
  return s;
}
