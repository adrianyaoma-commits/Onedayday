import customtkinter as ctk
import json
import os
import uuid
import subprocess
from datetime import date, datetime
from tkinter import filedialog, messagebox

# ── Constants ──────────────────────────────────────────────────────────────
TODAY = date.today().isoformat()
DATA_FILE = "todos.json"
DEVICES = ["Mac", "iPhone", "iPad", "Apple Watch"]

# Quadrant border accent colors (no emoji, pure colour semantics)
Q_COLORS = {
    "q1": "#FF3B30",  # Red    – Important & Urgent
    "q2": "#FF9500",  # Orange – Important & Not Urgent
    "q3": "#FFCC00",  # Gold   – Not Important & Urgent
    "q4": "#34C759",  # Green  – Not Important & Not Urgent
}
Q_TITLES = {
    "q1": "Important & Urgent",
    "q2": "Important & Not Urgent",
    "q3": "Not Important & Urgent",
    "q4": "Not Important & Not Urgent",
}


# ── Data helpers ───────────────────────────────────────────────────────────
def load_todos():
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def save_todos(todos):
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(todos, f, ensure_ascii=False, indent=2)


def clone_overdue(todos):
    """Clone every uncompleted task whose date is before today to today.
    The original is left untouched; a new task with ``cloned_from`` is appended."""
    changed = False
    for t in todos:
        if t.get("completed", False):
            continue
        if t.get("date", "") < TODAY:
            clone = dict(t)
            clone["id"] = uuid.uuid4().hex[:8]
            clone["date"] = TODAY
            clone["cloned_from"] = t["id"]
            clone["created_date"] = t.get("created_date", t["date"])
            todos.append(clone)
            changed = True
    return changed


def quadrant_key(t):
    """Return quadrant id for a task."""
    imp = t.get("important", False)
    urg = t.get("urgent", False)
    if imp and urg:
        return "q1"
    if imp and not urg:
        return "q2"
    if not imp and urg:
        return "q3"
    return "q4"


# ── Add / Edit dialog ──────────────────────────────────────────────────────
class TaskDialog(ctk.CTkToplevel):
    def __init__(self, parent, task=None, preset_q=None):
        super().__init__(parent)
        self.title("New Task" if task is None else "Edit Task")
        self.geometry("440x340")
        self.resizable(False, False)
        self.grab_set()

        self.result = None
        self._task = task

        # If preset_q given, lock important / urgent radios
        if preset_q == "q1":
            self._locked_imp, self._locked_urg = True, True
        elif preset_q == "q2":
            self._locked_imp, self._locked_urg = True, False
        elif preset_q == "q3":
            self._locked_imp, self._locked_urg = False, True
        elif preset_q == "q4":
            self._locked_imp, self._locked_urg = False, False
        else:
            self._locked_imp = self._locked_urg = False

        # Name
        ctk.CTkLabel(self, text="Task Name").grid(row=0, column=0, padx=20, pady=(20, 2), sticky="w")
        self.name_var = ctk.StringVar(value=task["name"] if task else "")
        self.name_entry = ctk.CTkEntry(self, width=380, textvariable=self.name_var)
        self.name_entry.grid(row=1, column=0, columnspan=2, padx=20, pady=(0, 10), sticky="w")

        # Device
        ctk.CTkLabel(self, text="Device").grid(row=2, column=0, padx=20, pady=(0, 2), sticky="w")
        self.device_var = ctk.StringVar(value=task["device"] if task else DEVICES[0])
        ctk.CTkOptionMenu(self, variable=self.device_var, values=DEVICES, width=140).grid(
            row=3, column=0, padx=20, pady=(0, 10), sticky="w"
        )

        # File
        self.file_var = ctk.StringVar(value=task.get("file_path", "") if task else "")
        ctk.CTkButton(self, text="Bind File", width=100, command=self._pick_file).grid(
            row=3, column=1, padx=(10, 20), pady=(0, 10), sticky="w"
        )
        ctk.CTkLabel(self, text="", textvariable=self.file_var, width=260, anchor="w").grid(
            row=4, column=0, columnspan=2, padx=20, pady=(0, 8), sticky="w"
        )

        # Important
        self.imp_var = ctk.BooleanVar(value=task["important"] if task else (self._locked_imp))
        s = ctk.CTkSwitch(self, text="Important", variable=self.imp_var)
        s.grid(row=5, column=0, padx=20, pady=(0, 2), sticky="w")
        if self._locked_imp:
            s.configure(state="disabled")

        # Urgent
        self.urg_var = ctk.BooleanVar(value=task["urgent"] if task else (self._locked_urg))
        s = ctk.CTkSwitch(self, text="Urgent", variable=self.urg_var)
        s.grid(row=5, column=1, padx=20, pady=(0, 2), sticky="w")
        if self._locked_urg:
            s.configure(state="disabled")

        # Buttons
        ctk.CTkButton(self, text="Save", command=self._save).grid(
            row=6, column=0, padx=20, pady=20, sticky="e"
        )
        ctk.CTkButton(self, text="Cancel", fg_color="gray", command=self.destroy).grid(
            row=6, column=1, padx=20, pady=20, sticky="w"
        )

    def _pick_file(self):
        path = filedialog.askopenfilename(title="Select a file to bind")
        if path:
            self.file_var.set(path)

    def _save(self):
        name = self.name_var.get().strip()
        if not name:
            messagebox.showwarning("Missing", "Task name is required.")
            return
        self.result = {
            "name": name,
            "device": self.device_var.get(),
            "file_path": self.file_var.get(),
            "important": self.imp_var.get(),
            "urgent": self.urg_var.get(),
        }
        self.destroy()


# ── Task card widget ────────────────────────────────────────────────────────
class TaskCard(ctk.CTkFrame):
    def __init__(self, parent, task, on_update, on_delete):
        color = Q_COLORS.get(quadrant_key(task), "#555555")
        super().__init__(parent, fg_color="#1c1c1e", border_width=1, border_color=color, corner_radius=8)
        self.task = task
        self.on_update = on_update
        self.on_delete = on_delete
        self._build()

    def _build(self):
        t = self.task
        q = quadrant_key(t)

        # Row 0 – name (bold-like)
        name_text = t["name"]
        lbl = ctk.CTkLabel(self, text=name_text, font=ctk.CTkFont(size=13, weight="bold"), anchor="w")
        lbl.grid(row=0, column=0, columnspan=3, padx=10, pady=(8, 0), sticky="w")

        # Row 1 – clone origin label
        r = 1
        if t.get("cloned_from"):
            origin_date = t.get("created_date", "?")
            ctk.CTkLabel(
                self,
                text=f"[Begun: {origin_date}]",
                font=ctk.CTkFont(size=10, slant="italic"),
                text_color="#8E8E93",
                anchor="w",
            ).grid(row=r, column=0, columnspan=3, padx=10, pady=(0, 0), sticky="w")
            r += 1

        # Row r – device + file
        device_text = t.get("device", "Mac")
        file_path = t.get("file_path", "")

        ctk.CTkLabel(self, text=device_text, font=ctk.CTkFont(size=10), text_color="#8E8E93").grid(
            row=r, column=0, padx=10, pady=(2, 0), sticky="w"
        )
        if file_path:
            fname = os.path.basename(file_path)
            ctk.CTkLabel(self, text=fname, font=ctk.CTkFont(size=10), text_color="#8E8E93").grid(
                row=r, column=1, padx=6, pady=(2, 0), sticky="w"
            )
            self.open_btn = ctk.CTkButton(
                self, text="Open", width=48, height=22,
                font=ctk.CTkFont(size=10),
                command=lambda: subprocess.call(["open", file_path]),
            )
            self.open_btn.grid(row=r, column=2, padx=(4, 10), pady=(2, 0), sticky="e")
        else:
            self.open_btn = None

        # Row r+1 – actions
        r += 1

        # Complete checkbox
        self.comp_var = ctk.BooleanVar(value=t.get("completed", False))
        cb = ctk.CTkCheckBox(
            self, text="Done", variable=self.comp_var,
            command=self._toggle_complete, width=20,
        )
        cb.grid(row=r, column=0, padx=10, pady=(4, 8), sticky="w")

        # Edit
        ctk.CTkButton(
            self, text="Edit", width=48, height=22,
            font=ctk.CTkFont(size=10),
            command=self._edit,
        ).grid(row=r, column=1, padx=6, pady=(4, 8), sticky="w")

        # Delete
        ctk.CTkButton(
            self, text="Delete", width=48, height=22,
            font=ctk.CTkFont(size=10),
            fg_color="#8E1E1E", hover_color="#B02A2A",
            command=self._delete,
        ).grid(row=r, column=2, padx=(4, 10), pady=(4, 8), sticky="e")

    def _toggle_complete(self):
        self.task["completed"] = self.comp_var.get()
        self.on_update()

    def _edit(self):
        dlg = TaskDialog(self.winfo_toplevel(), task=self.task)
        self.wait_window(dlg)
        if dlg.result:
            for k, v in dlg.result.items():
                self.task[k] = v
            self.on_update()

    def _delete(self):
        self.on_delete(self.task["id"])


# ── Quadrant panel ──────────────────────────────────────────────────────────
class QuadrantPanel(ctk.CTkFrame):
    def __init__(self, parent, qid, app):
        color = Q_COLORS[qid]
        super().__init__(parent, fg_color="#0d0d0d", border_width=2, border_color=color, corner_radius=12)
        self.qid = qid
        self.app = app

        # Title bar
        bar = ctk.CTkFrame(self, fg_color=color, corner_radius=0, height=32)
        bar.pack(fill="x")
        ctk.CTkLabel(bar, text=Q_TITLES[qid], font=ctk.CTkFont(size=13, weight="bold"), text_color="#000000").pack(pady=4)

        # Scrollable task list
        self.task_list = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.task_list.pack(fill="both", expand=True, padx=6, pady=4)

        # Add button
        ctk.CTkButton(
            self, text="+ Add Task", height=28,
            font=ctk.CTkFont(size=11),
            command=self._add_task,
        ).pack(fill="x", padx=8, pady=(0, 8))

    def _add_task(self):
        dlg = TaskDialog(self.winfo_toplevel(), preset_q=self.qid)
        self.wait_window(dlg)
        if dlg.result:
            new_task = {
                "id": uuid.uuid4().hex[:8],
                "name": dlg.result["name"],
                "device": dlg.result["device"],
                "file_path": dlg.result["file_path"],
                "important": dlg.result["important"],
                "urgent": dlg.result["urgent"],
                "date": TODAY,
                "created_date": TODAY,
                "completed": False,
            }
            self.app._todos.append(new_task)
            self.app._save_and_refresh()

    def refresh(self, tasks):
        for w in self.task_list.winfo_children():
            w.destroy()
        for t in tasks:
            if quadrant_key(t) != self.qid:
                continue
            card = TaskCard(
                self.task_list, t,
                on_update=self.app._save_and_refresh,
                on_delete=self.app._delete_task,
            )
            card.pack(fill="x", padx=4, pady=3)


# ── Main App ────────────────────────────────────────────────────────────────
class TodoApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("dark-blue")

        self.title("Onedayday")
        self.geometry("1200x820")
        self.minsize(960, 640)

        self._todos = load_todos()

        # Clone overdue tasks to today
        if clone_overdue(self._todos):
            save_todos(self._todos)

        # Top bar
        top = ctk.CTkFrame(self, fg_color="transparent")
        top.pack(fill="x", padx=12, pady=(10, 4))

        ctk.CTkLabel(top, text="Onedayday", font=ctk.CTkFont(size=22, weight="bold")).pack(side="left", padx=6)
        ctk.CTkLabel(top, text=TODAY, font=ctk.CTkFont(size=13), text_color="#8E8E93").pack(side="left", padx=12)

        self._toggle_var = ctk.BooleanVar(value=False)
        ctk.CTkSwitch(top, text="Show completed", variable=self._toggle_var, command=self._refresh_all).pack(side="right", padx=12)
        ctk.CTkButton(top, text="Save Now", width=80, height=28, command=self._save).pack(side="right", padx=4)
        ctk.CTkButton(top, text="New Task (free)", width=100, height=28, command=self._add_free).pack(side="right", padx=4)

        # Quadrant grid
        grid = ctk.CTkFrame(self, fg_color="transparent")
        grid.pack(fill="both", expand=True, padx=10, pady=6)
        grid.grid_columnconfigure(0, weight=1, uniform="col")
        grid.grid_columnconfigure(1, weight=1, uniform="col")
        grid.grid_rowconfigure(0, weight=1, uniform="row")
        grid.grid_rowconfigure(1, weight=1, uniform="row")

        self.panels = {}
        for idx, qid in enumerate(["q1", "q2", "q3", "q4"]):
            panel = QuadrantPanel(grid, qid, self)
            panel.grid(row=idx // 2, column=idx % 2, padx=6, pady=6, sticky="nsew")
            self.panels[qid] = panel

        # Status bar
        status = ctk.CTkFrame(self, fg_color="transparent", height=24)
        status.pack(fill="x", padx=16, pady=(0, 8))
        total = len([t for t in self._todos if not t.get("completed")])
        ctk.CTkLabel(status, text=f"Active: {total}", font=ctk.CTkFont(size=10), text_color="#8E8E93").pack(side="left")

        self._refresh_all()

    # ── actions ─────────────────────────────────────────────────────────
    def _save(self):
        save_todos(self._todos)

    def _save_and_refresh(self):
        save_todos(self._todos)
        self._refresh_all()

    def _refresh_all(self):
        show_completed = self._toggle_var.get()
        visible = [t for t in self._todos if not t.get("completed") or show_completed]
        for panel in self.panels.values():
            panel.refresh(visible)

    def _add_free(self):
        dlg = TaskDialog(self)
        self.wait_window(dlg)
        if dlg.result:
            new_task = {
                "id": uuid.uuid4().hex[:8],
                "name": dlg.result["name"],
                "device": dlg.result["device"],
                "file_path": dlg.result["file_path"],
                "important": dlg.result["important"],
                "urgent": dlg.result["urgent"],
                "date": TODAY,
                "created_date": TODAY,
                "completed": False,
            }
            self._todos.append(new_task)
            self._save_and_refresh()

    def _delete_task(self, task_id):
        self._todos = [t for t in self._todos if t.get("id") != task_id]
        self._save_and_refresh()


# ── Entry point ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    app = TodoApp()
    app.mainloop()
