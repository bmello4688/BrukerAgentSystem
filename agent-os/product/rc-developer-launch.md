# RC Developer Launch

Use `scripts/launch-rc-dev.ps1` for the RC local developer/demo profile. It starts the backend host first, waits for the required local runtime ports, then starts the Uno desktop UI.

## Command

From the repository root:

```powershell
.\scripts\launch-rc-dev.ps1
```

Command Prompt wrapper:

```cmd
scripts\launch-rc-dev.cmd
```

After the projects have already been built, this faster form can be used:

```powershell
.\scripts\launch-rc-dev.ps1 -NoBuild
```

Backend-only smoke check:

```powershell
.\scripts\launch-rc-dev.ps1 -StopAfterReady
```

## Startup Order

1. `MrmEtdMassSpecAnalyzer.MicroServices.Host`
2. `TripleQuadHardware.Service` on `7043`
3. `SubstanceAnalyzerCore.Service` on `7042`
4. Simulator communication service on loopback `7044`
5. Uno desktop UI using `net10.0-desktop`

The backend host currently runs in simulator mode for RC. The script fails fast if any of the required ports are already in use.

## Runtime Ports

| Component | Address |
| --- | --- |
| Core service | `http://localhost:7042` |
| Hardware service | `http://localhost:7043` |
| Simulator communication service | `http://127.0.0.1:7044` |

The individual ASP.NET launch ports in project launch settings are not the RC client runtime ports.

## DataService Boundary

DataService startup and access remain owned by `SubstanceAnalyzerCore.Service`. The RC profile does not start DataService as a separate UI, simulator, or loose developer component.

## Production Posture

RC production posture is documentation only:

- Windows is the supported runtime target for RC.
- Future production microservices should run as Windows Services.
- The Uno UI is operator-launched or kiosk auto-launched on the workstation.
- This RC profile does not install Windows Services, implement kiosk lockdown, or provide a production installer.

## Validation

Minimum smoke validation:

1. Run `.\scripts\launch-rc-dev.ps1`.
2. Confirm the script reports listeners on ports `7042`, `7043`, and `7044`.
3. Confirm the Uno desktop UI launches.
4. Use the simulator-driven RC workflow for collection/alarm/history validation.

Simulator validation is separate from real hardware/manual validation.

Latest BL-014 validation on 2026-06-11 from branch `feature/rc-single-dev-launch-profile`, commit `d716ddc`:

- Rebased cleanly onto local `master` after BL-013 merge.
- Branch diff contains `scripts/launch-rc-dev.ps1` plus `.cmd` wrappers for tracked parent-repo PowerShell scripts.
- Submodules synced to recorded commits using local clones where the internal Git host was not resolvable in the review environment.
- `dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.MicroServices.Host\MrmEtdMassSpecAnalyzer.MicroServices.Host.csproj" --no-restore` passed with existing warnings and `0 Error(s)`.
- `dotnet build "MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.csproj" -f net10.0-desktop --no-restore` passed with existing warnings and `0 Error(s)`.
- `.\scripts\launch-rc-dev.ps1 -NoBuild -StopAfterReady -StartupTimeoutSeconds 90` confirmed listeners on `7042`, `7043`, and `7044`, then shut down the backend host cleanly.
- `cmd.exe /c scripts\launch-rc-dev.cmd -NoBuild -StopAfterReady -StartupTimeoutSeconds 90` confirmed the `.cmd` wrapper forwards arguments, starts listeners on `7042`, `7043`, and `7044`, then shuts down cleanly.

Remaining review item: full simulator UI workflow demo/signoff.
