# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

## TripleQuadUI Desktop Workflow Tools

- Windows SDK Inspect: `C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\inspect.exe`
- FlaUInspect: `C:\Users\brian.mello\AppData\Local\Microsoft\WinGet\Packages\FlaUI.FlaUInspect_Microsoft.Winget.Source_8wekyb3d8bbwe\FlaUInspect.exe`
- Appium: `appium` via npm global, version 3.5.0
- Appium Windows driver: `windows@5.4.1`, automationName `Windows`

Use Inspect or FlaUInspect for quick UI Automation tree review of TripleQuadUI and DHS-GUI behavior. Use Appium Windows driver when a repeatable UI workflow test is useful. Keep any generated test scripts or notes outside the Bruker Detection Git repo unless Brian explicitly asks to add production tests.

## Related

- [Agent workspace](/concepts/agent-workspace)
