MikroTik PPPoE link-up watcher → Telegram

Overview
This repository contains MikroTik RouterOS scripts for monitoring PPPoE interface status with Telegram notifications:
- Main monitoring script that detects when a PPPoE interface comes back up and sends a formatted notification to a Telegram chat. It keeps a running count of link downs (as reported by RouterOS), includes timestamps for the last DOWN and last UP events, and avoids duplicate messages using debounce and an anti-duplicate guard.
- Testing utility script that resets all global variables to emulate router reboot and observe script behavior.

What the script does
- Monitors a PPPoE interface’s last-link-up-time and last-link-down-time.
- Debounces readings (requires two consecutive identical reads) to reduce false triggers during rapid updates.
- Uses a simple mutex to prevent overlapping executions when scheduled frequently.
- Sends a Telegram message in the exact format below when a new UP event is detected:

  <ver>: <iface>
  Total downs: <downs>
  Last DOWN: <lastDown>
  Last UP:        <lastUp>

Requirements
- RouterOS: tested with RouterOS 7.20.x.
- An existing PPPoE client interface on the router.
- A Telegram bot token and a target chat ID.

Configuration
Open last-link-up-time.rsc and adjust these variables near the top of the file:
- scriptVersion: script version label used in logs/messages (optional).
- pppInterfaceName: name of your PPPoE interface, e.g. "Telekom-pppoe-out".
- telegramBotToken: your Telegram bot token.
- telegramChatId: the numeric chat ID (or @channel_username if you allow it).

How it works (internals)
- Reads interface fields: last-link-up-time, last-link-down-time, and link-downs (with error protection).
- Debounce logic: only reacts when last-link-up-time is stable across two consecutive reads (frCandUp/frCandSeen).
- Anti-duplicate: remembers the last notified last-link-up-time (frNotifiedUp) to avoid re-sending the same UP event.
- Mutex (frBusy): prevents concurrent runs if the scheduler interval is short.
- Minimal URL encoding: spaces and line breaks are encoded; keep message content simple (ASCII) for reliability.

Installation (via RouterOS Script + Scheduler)
1) Create a RouterOS script from the file content:
   - WinBox/WebFig: System → Scripts → Add New → paste contents of last-link-up-time.rsc → name it e.g. FRv5.0-uptime-watch.
   - IMPORTANT: set Policy to read, write, test, policy for this script.
   - CLI example:
     /system script add name=FRv5.0-uptime-watch policy=read,write,test,policy source="<paste the file content here>"

2) Schedule execution on startup and every 5 seconds:
   - WinBox/WebFig: System → Scheduler → Add New
       • On Event: /system script run FRv5.0-uptime-watch
       • Start Time: startup
       • Interval: 00:00:05
       • Policy: read, write, test, policy (must match the script’s policies)
   - CLI example:
     /system scheduler add name=fr-uptime-watch on-event="/system script run FRv5.0-uptime-watch" start-time=startup interval=5s policy=read,write,test,policy

Notes
- The script is designed for periodic polling. Debounce and anti-duplicate guards minimize redundant messages.
- Ensure the ppp variable exactly matches your PPPoE interface name.
- Store tgToken securely; consider restricting bot exposure and using private chats.
- Make sure both the script and the scheduler entry have policies set to read, write, test, policy. Otherwise, RouterOS may not persist global variables as expected until the next run.

Files
- last-link-up-time.rsc — the main RouterOS monitoring script you install on your router (scheduled to run periodically).
- reset-global-vars.rsc — testing/debugging utility script that resets all global variables used by the monitoring script.

Testing and debugging (reset-global-vars.rsc)
The reset-global-vars.rsc script allows you to emulate a router reboot by clearing all global variables (frPrevLastUp, tgText, frCandUp, frCandSeen, frNotifiedUp, frBusy) used by the main monitoring script. This is useful for:
- Testing how the main script behaves on first run (when no variables are set).
- Observing script reaction after simulated reboot without actually rebooting the router.
- Debugging anti-duplicate and debounce logic.

Usage:
1) Install as a script: /system script add name=FRv5.0-reset-vars policy=read,write,test,policy source="<paste reset-global-vars.rsc content>"
2) Run manually when needed: /system script run FRv5.0-reset-vars
3) Check logs to see which variables were reset: /log print where message~"FRv5.0-reset"

IDE syntax highlighting (VS Code and JetBrains)
- The folder vscode_mikrotik_routeros_script-master contains a VS Code extension that provides syntax highlighting for MikroTik RouterOS scripts.
- You can also use this syntax in JetBrains IDEs (IntelliJ IDEA, WebStorm, etc.):
- Install the "TextMate Bundles" plugin (Settings → Plugins → Marketplace).
- Go to Settings → Editor → TextMate Bundles → Add → select the folder vscode_mikrotik_routeros_script-master (or its syntaxes subfolder).
- The RouterOS script syntax highlighting will be applied to .rsc files.

License
If a license file is present in this repository (e.g., in a subfolder), it applies to that component. This root script can be used under the terms of the repository’s chosen license, or consider MIT by default if none is specified.
