# Tutorial: Windows PowerShell 7 & WSL2 Integration

> **Type:** Diátaxis Tutorial (Learning-oriented, hands-on)  
> **Goal:** Link your Windows host terminal (`pwsh.exe`) to the WSL2 dotfiles repository over the UNC profile bridge  
> **Prerequisites:** Windows 11 / 10 with WSL2 installed; PowerShell 7 (`pwsh.exe`) installed on Windows  

---

## 1. Prerequisites Check

Open an administrative or standard Windows terminal and confirm that PowerShell 7 is installed:
```powershell
pwsh --version
# Expected: PowerShell 7.4.x or higher
```

Confirm that your WSL distribution is running:
```powershell
wsl -l -v
# Expected: Ubuntu (or default distro) running WSL version 2
```

---

## 2. Step 1: Clone Dotfiles inside WSL

Launch your WSL terminal (e.g. Ubuntu):
```bash
git clone https://github.com/SPRIME01/dotfiles "$HOME/dotfiles"
cd "$HOME/dotfiles"
bash install.sh
```
*Expected Result:* `chezmoi` renders templates, and `bootstrap.sh` sets up shell symlinks.

---

## 3. Step 2: Generate the Windows Bootstrap Profile

From inside your WSL terminal, run:
```bash
just setup-pwsh7
```

*What this does:*
1. Discovers your Windows username using `pwsh.exe -Command '$env:USERNAME'`.
2. Locates your Windows user profile path (handles OneDrive folder redirection automatically).
3. Writes the disposable bootstrap profile to `C:\Users\<user>\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`.
4. Configures the UNC bridge path: `\\wsl.localhost\Ubuntu\home\sprime01\dotfiles`.

*Expected Output:*
```
🔧 Setting up PowerShell 7 (pwsh) Windows profile...
✅ Windows PowerShell 7 profile updated successfully!
```

---

## 4. Step 3: Verify the Windows Profile

Open a brand new Windows Terminal tab running **PowerShell 7**.

You should see:
1. Terminal prompt renders with Oh My Posh in under 250 milliseconds.
2. Icons rendered next to folders and files.

Verify that cross-host navigation works:
```powershell
projects
# Navigates to your projects folder ($env:USERPROFILE\projects or ~/projects)

cddot
# Navigates to the dotfiles directory over UNC: \\wsl.localhost\Ubuntu\home\sprime01\dotfiles
```

Verify that developer aliases work:
```powershell
gs
# Runs Get-GitStatus via the lazy-loading proxy
```

---

## 5. What to Read Next
- Learn how the UNC bridge works under the hood in [Cross-Platform Host Bridge Subsystem](../subsystems/powershell-host-bridge.md).
- Follow the execution trace in [Windows PowerShell UNC Startup Workflow](../workflows/powershell-unc-startup.md).
