// Today — Figma/FigJam widget. A live to-do that lives on the canvas; state is
// synced into the document via useSyncedState. Written in plain JS using the
// widget hyperscript API (figma.widget.h) so there's no JSX/build step.

const { widget } = figma;
const { AutoLayout, Text, Input, SVG, useSyncedState, usePropertyMenu } = widget;
const h = widget.h;

const CHECKED =
  '<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg"><circle cx="9" cy="9" r="9" fill="#4B48F5"/><path d="M5 9l3 3 5-6" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const EMPTY =
  '<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg"><circle cx="9" cy="9" r="8" fill="none" stroke="#b9b9ad" stroke-width="1.6"/></svg>';

function Today() {
  const [tasks, setTasks] = useSyncedState("tasks", []);
  const [draft, setDraft] = useSyncedState("draft", "");

  usePropertyMenu(
    [{ itemType: "action", propertyName: "clear", tooltip: "Clear completed" }],
    ({ propertyName }) => {
      if (propertyName === "clear") setTasks(tasks.filter((t) => !t.done));
    }
  );

  function add(text) {
    const t = (text || "").trim();
    if (!t) return;
    setTasks([...tasks, { id: Date.now().toString(36), title: t, done: false }]);
  }
  function toggle(id) {
    setTasks(tasks.map((t) => (t.id === id ? Object.assign({}, t, { done: !t.done }) : t)));
  }
  const left = tasks.filter((t) => !t.done).length;

  return h(
    AutoLayout,
    {
      direction: "vertical", spacing: 12, padding: 20, cornerRadius: 16, width: 280,
      fill: "#FFFFFF", stroke: "#E7E7E1", strokeWidth: 1,
      effect: { type: "drop-shadow", color: { r: 0, g: 0, b: 0, a: 0.08 }, offset: { x: 0, y: 6 }, blur: 20 },
    },
    h(
      AutoLayout,
      { direction: "horizontal", width: "fill-parent", verticalAlignItems: "center" },
      h(Text, { fontSize: 18, fontWeight: 700, fill: "#141611" }, "Today"),
      h(AutoLayout, { width: "fill-parent" }),
      h(Text, { fontSize: 12, fill: "#8a8a80" }, left + " left")
    ),
    h(Input, {
      value: draft,
      placeholder: "Add a task…",
      onTextEditEnd: (e) => { add(e.characters); setDraft(""); },
      fontSize: 14, fill: "#141611", width: "fill-parent",
      inputFrameProps: { fill: "#F3F2EC", cornerRadius: 8, padding: 10 },
      placeholderProps: { fill: "#9a9a8c" },
    }),
    tasks.length === 0
      ? h(Text, { fontSize: 13, fill: "#9a9a8c" }, "Nothing yet — add a task.")
      : tasks.map((t) =>
          h(
            AutoLayout,
            {
              key: t.id, direction: "horizontal", spacing: 10, verticalAlignItems: "center",
              width: "fill-parent", padding: { vertical: 3 }, onClick: () => toggle(t.id),
            },
            h(SVG, { src: t.done ? CHECKED : EMPTY }),
            h(Text, {
              fontSize: 14, width: "fill-parent",
              fill: t.done ? "#b3b3a8" : "#141611",
              textDecoration: t.done ? "strikethrough" : "none",
            }, t.title)
          )
        )
  );
}

widget.register(Today);
