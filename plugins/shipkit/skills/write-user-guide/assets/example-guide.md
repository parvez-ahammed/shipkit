# Recurring tasks

*Acme Tasks - Feature guide*

Make a task come back on a schedule. Each time you complete it, Acme Tasks makes the next copy with the next due date. Nothing happens on a timer: the next copy appears only when you complete the current one.

- **Where:** **Task details**, field **Repeat**
- **Who:** **Project Owner** on any task. **Member** on tasks assigned to them.
- **Shown in:** the task **List** and the **Calendar**, with a repeat icon

## Make a task repeat

1. **Open the task.** Select the task in the list. **Task details** opens.
2. **Give it a due date.** The **Repeat** field stays disabled until the task has a due date.
3. **Choose how often.** In **Repeat**, select **Daily**, **Weekly**, **Monthly** or **Custom...**. To stop after a number of copies, also fill in **Ends after**.

The task now shows the repeat icon in the list and the calendar.

## What happens when you complete it

When you mark the task **Done**, Acme Tasks makes one new copy. The copy keeps the title, assignee, labels and checklist. It starts without comments or attachments; those stay on the copy you completed.

**Example:** "Send the weekly report" repeats **Weekly** and is due Monday 4 May.

| You do this | Acme Tasks does this |
|---|---|
| Mark it Done on Monday 4 May | Makes a copy due Monday 11 May, and shows "Next task created for 11 May." |
| Complete the 11 May copy three days late, on Thursday 14 May | Makes a copy due Monday 18 May. The next date counts from the old due date, not from the day you completed it. |
| Leave the 18 May copy open past its due date | Nothing. The task shows as overdue. No new copy is made until you complete it. |

It works the same wherever the task is marked Done: in the list, on the board, in **Task details**, or by a rule in **Automations** (for example "close the task when the linked pull request is merged").

## When no copy is made

- **The due date passes.** The task stays open and overdue.
- **You delete the task.** The repeat stops for good.
- **You move a Done task back to Open.** The copy that was already made stays.
- **The project is archived.** Tasks in an archived project cannot be completed, so no copies are made.

## Stop or end the repeat

- **Stop now:** set **Repeat** to **Never**. When you complete the task, no copy is made.
- **Stop after a number of copies:** set **Ends after** (1 to 365). The last copy shows "Last in series" next to its due date.

## Who can do what

| Role | Set, change or stop the repeat |
|---|---|
| Project Owner | On any task in the project |
| Member | Only on tasks assigned to them |
| Viewer | No. Viewers see the repeat icon, but the **Repeat** field is read-only. |

## Fields in Task details

| Field | What it does |
|---|---|
| Repeat | How often the task repeats: **Never**, **Daily**, **Weekly**, **Monthly** or **Custom...** |
| Ends after | The number of copies before the repeat stops, from 1 to 365. Empty means it does not stop. |
| Next due | Read-only. The due date the next copy will get. |

## Messages you may see

| Type | Message | What to do |
|---|---|---|
| Info | "Next task created for 12 May." | Nothing. The new copy is in the list with that due date. |
| Warning | "Set a due date to repeat this task." | Set a due date first, then choose a repeat. |
| Error | "Could not create the next task. Try again." | The task is Done, but no copy was made. Move the task back to Open, then mark it Done again. |

## Good to know

> **Only the next copy exists.** Copies are not made in advance, so the calendar shows only the next one, not the weeks after it.

> **Monthly tasks due on the 31st.** In a shorter month the copy is due on the last day of the month.
