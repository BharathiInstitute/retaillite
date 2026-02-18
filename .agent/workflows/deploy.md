---
description: Smart interactive deploy - asks questions, runs tests, builds, deploys, updates config
---

# Smart Deploy Workflow

Run the interactive smart deploy script that guides you through the entire deployment process.

## Steps

// turbo
1. Run the smart deploy script:
```powershell
.\smart-deploy.ps1
```

The script will interactively ask you:

### Questions Asked
1. **Update Type** — Normal 🟢 / Patch 🟡 / Critical 🔴 / Maintenance 🛑 / Config Only ⚙️
2. **Platforms** — Web / Windows / Android / combinations
3. **Version Bump** — Build / Patch / Minor / Major / Custom
4. **Changelog** — What changed (line by line)
5. **Confirm** — Review summary before proceeding

### Automated Steps (after confirmation)
1. ✅ Runs `flutter test` — blocks if tests fail
2. ✅ Runs `flutter analyze` — blocks if issues found
3. 🏗️ Builds for selected platforms
4. 🚀 Deploys web to Firebase Hosting
5. 📝 Updates `version.json` for Windows auto-update
6. ⚙️ Prompts to update Remote Config for critical/maintenance
7. 🏷️ Creates git commit + version tag
8. 📤 Pushes to remote

### Update Types Explained
| Type | When | What Happens |
|---|---|---|
| 🟢 Normal | New feature, UI change | Auto-update, no force |
| 🟡 Patch | Bug fix | Auto-update, recommended |
| 🔴 Critical | Breaking change, security | BLOCKS old users via min_app_version |
| 🛑 Maintenance | Server down, migration | BLOCKS ALL users, no build |
| ⚙️ Config Only | Remote Config change | No build, just config update |
