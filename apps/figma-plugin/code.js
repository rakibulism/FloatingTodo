// Today — Figma/FigJam plugin (main thread).
// Shows the to-do UI, persists with figma.clientStorage, and can drop the list
// onto the canvas (sticky notes in FigJam, a text frame in Figma).

const KEY = "today.data";

figma.showUI(__html__, { width: 360, height: 560, title: "Today", themeColors: true });

async function loadData() {
  return (await figma.clientStorage.getAsync(KEY)) || { todos: [], must: [] };
}
async function saveData(data) {
  await figma.clientStorage.setAsync(KEY, data);
}

figma.ui.onmessage = async (msg) => {
  if (msg.type === "ready") {
    figma.ui.postMessage({ type: "data", data: await loadData() });
  } else if (msg.type === "save") {
    await saveData(msg.data);
  } else if (msg.type === "insert") {
    await insertList(msg.data);
  } else if (msg.type === "notify") {
    figma.notify(msg.text);
  }
};

function lines(data) {
  const must = (data.must || []).map((t) => "🔒 " + t.title);
  const todos = (data.todos || []).map((t) => (t.done ? "✓ " : "○ ") + t.title);
  return [...must, ...todos];
}

async function insertList(data) {
  const items = lines(data);
  if (items.length === 0) {
    figma.notify("Nothing to insert — add a task first.");
    return;
  }
  const c = figma.viewport.center;

  if (figma.editorType === "figjam") {
    const created = [];
    let x = c.x - (items.length * 120);
    for (const text of items) {
      const s = figma.createSticky();
      await figma.loadFontAsync(s.text.fontName);
      s.text.characters = text;
      s.x = x; s.y = c.y; x += 250;
      created.push(s);
    }
    figma.currentPage.selection = created;
    figma.viewport.scrollAndZoomIntoView(created);
  } else {
    await figma.loadFontAsync({ family: "Inter", style: "Regular" });
    await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
    const frame = figma.createFrame();
    frame.name = "Today";
    frame.layoutMode = "VERTICAL";
    frame.itemSpacing = 10;
    frame.paddingTop = frame.paddingBottom = frame.paddingLeft = frame.paddingRight = 20;
    frame.primaryAxisSizingMode = "AUTO";
    frame.counterAxisSizingMode = "AUTO";
    frame.cornerRadius = 12;
    frame.fills = [{ type: "SOLID", color: { r: 0.07, g: 0.07, b: 0.09 } }];

    const title = figma.createText();
    title.fontName = { family: "Inter", style: "Semi Bold" };
    title.characters = "Today";
    title.fontSize = 20;
    title.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    frame.appendChild(title);

    for (const text of items) {
      const t = figma.createText();
      t.fontName = { family: "Inter", style: "Regular" };
      t.characters = text;
      t.fontSize = 14;
      t.fills = [{ type: "SOLID", color: { r: 0.9, g: 0.9, b: 0.93 } }];
      frame.appendChild(t);
    }
    frame.x = c.x - frame.width / 2;
    frame.y = c.y - frame.height / 2;
    figma.currentPage.selection = [frame];
    figma.viewport.scrollAndZoomIntoView([frame]);
  }
  figma.notify("Inserted your list ✦");
}
