# Helpers for capturing documentation screenshots from a background MCUViewer instance.
#
# The instance runs with its own %APPDATA% (so the user's config, recent projects and layout are never
# touched), sits outside of the visible desktop (so the real mouse cursor never reaches it) and is
# driven through window messages and the built-in MCP server. All coordinates passed to the functions
# below are screenshot coordinates - pixels of the captured 1326x1032 image, title bar included.
#
# Usage: . .\ShotLib.ps1 ; Use-ShotInstance (or Start-ShotInstance) ; Invoke-ShotClick 75 42 ; Save-Shot name

Add-Type -AssemblyName System.Drawing

$script:ShotRoot = $PSScriptRoot
$script:ShotRawDir = Join-Path $PSScriptRoot "raw"
$script:ShotWorkDir = Join-Path $env:TEMP "mcuviewer-docs-shots"
$script:ShotExe = "C:\Program Files\MCUViewer\bin\MCUViewer.exe"
$script:ShotWidth = 1326
$script:ShotHeight = 1032
$script:ShotHwnd = [IntPtr]::Zero
$script:ShotPid = 0
$script:McpSession = $null
$script:McpUrl = $null
$script:McpId = 0

if (-not ("ShotNative" -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public static class ShotNative
{
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr hWnd, ref POINT p);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int w, int h, uint flags);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder s, int n);
    [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr hWnd, int attr, out RECT r, int size);
    [DllImport("kernel32.dll")] static extern IntPtr OpenThread(uint access, bool inherit, uint tid);
    [DllImport("kernel32.dll")] static extern uint SuspendThread(IntPtr h);
    [DllImport("kernel32.dll")] static extern uint ResumeThread(IntPtr h);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);

    public static IntPtr FindMainWindow(uint pid)
    {
        IntPtr found = IntPtr.Zero;
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p == pid && IsWindowVisible(h) && GetWindowTextLength(h) > 0) { found = h; return false; }
            return true;
        }, IntPtr.Zero);
        return found;
    }

    public static string Title(IntPtr h)
    {
        var sb = new System.Text.StringBuilder(1024); GetWindowText(h, sb, 1024); return sb.ToString();
    }

    /* visible frame of the window, without the invisible resize borders of Windows 10/11 */
    public static RECT FrameBounds(IntPtr h)
    {
        RECT r; DwmGetWindowAttribute(h, 9 /*DWMWA_EXTENDED_FRAME_BOUNDS*/, out r, Marshal.SizeOf(typeof(RECT)));
        return r;
    }

    /* offset of the client area inside the visible frame - turns screenshot into client coordinates */
    public static POINT ClientOffset(IntPtr h)
    {
        POINT p = new POINT(); ClientToScreen(h, ref p);
        RECT f = FrameBounds(h);
        return new POINT { X = p.X - f.Left, Y = p.Y - f.Top };
    }

    public static POINT FrameOrigin(IntPtr h) { RECT f = FrameBounds(h); return new POINT { X = f.Left, Y = f.Top }; }

    /* sizes the window so that its visible frame is exactly w x h, placed at x,y */
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);

    public static void SetFrame(IntPtr h, int x, int y, int w, int hgt)
    {
        /* restores a minimized or maximized window without activating it, so the user's focus stays put */
        if (IsIconic(h)) ShowWindow(h, 4 /*SW_SHOWNOACTIVATE*/);
        ShowWindow(h, 4 /*SW_SHOWNOACTIVATE*/);
        RECT wr; GetWindowRect(h, out wr);
        RECT fr = FrameBounds(h);
        int dl = fr.Left - wr.Left, dt = fr.Top - wr.Top, dr = wr.Right - fr.Right, db = wr.Bottom - fr.Bottom;
        SetWindowPos(h, IntPtr.Zero, x - dl, y - dt, w + dl + dr, hgt + dt + db, 0x0004 /*NOZORDER*/ | 0x0010 /*NOACTIVATE*/);
    }

    /* captures the visible frame - works while the window is covered or outside of the desktop */
    public static void Capture(IntPtr h, string path)
    {
        RECT wr; GetWindowRect(h, out wr);
        RECT fr = FrameBounds(h);
        using (var full = new Bitmap(wr.Right - wr.Left, wr.Bottom - wr.Top, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(full))
            {
                IntPtr hdc = g.GetHdc();
                PrintWindow(h, hdc, 2 /*PW_RENDERFULLCONTENT*/);
                g.ReleaseHdc(hdc);
            }
            var crop = new Rectangle(fr.Left - wr.Left, fr.Top - wr.Top, fr.Right - fr.Left, fr.Bottom - fr.Top);
            using (var outBmp = full.Clone(crop, PixelFormat.Format24bppRgb))
                outBmp.Save(path, ImageFormat.Png);
        }
    }

    /* A sequence of input messages posted while the GUI thread is suspended, so that it lands in the
       queue as one uninterrupted block.

       Why: the real cursor is never over the window, so Windows answers the first WM_MOUSEMOVE with a
       WM_MOUSELEAVE, which moves the ImGui mouse off-screen. Posted as one block, the leave message
       comes after the whole sequence. ImGui merges consecutive mouse moves into one frame and needs
       mouse movement between two frames to re-enable hovering (e.g. in menus), so Break() inserts a
       press of an unused key (F24) that splits the sequence into separate frames. */
    public class Burst
    {
        readonly IntPtr hwnd;
        readonly List<uint> msgs = new List<uint>();
        readonly List<IntPtr> wps = new List<IntPtr>();
        readonly List<IntPtr> lps = new List<IntPtr>();
        int buttons = 0;

        public Burst(IntPtr hwnd) { this.hwnd = hwnd; }

        static IntPtr LP(int x, int y) { return (IntPtr)((y << 16) | (x & 0xFFFF)); }
        void Add(uint m, IntPtr w, IntPtr l) { msgs.Add(m); wps.Add(w); lps.Add(l); }

        public Burst Move(int x, int y) { Add(0x0200, (IntPtr)buttons, LP(x, y)); return this; }
        public Burst Down(int x, int y, int button) { buttons |= Mask(button); Add(DownMsg(button), (IntPtr)buttons, LP(x, y)); return this; }
        public Burst Up(int x, int y, int button) { buttons &= ~Mask(button); Add(UpMsg(button), (IntPtr)buttons, LP(x, y)); return this; }
        public Burst Key(int vk)
        {
            uint sc = 0; /* GLFW looks the scan code up from the virtual key when it is zero */
            Add(0x0100, (IntPtr)vk, (IntPtr)(1 | (int)(sc << 16)));
            Add(0x0101, (IntPtr)vk, unchecked((IntPtr)(int)(0xC0000001 | (sc << 16))));
            return this;
        }
        public Burst KeyDown(int vk) { Add(0x0100, (IntPtr)vk, (IntPtr)1); return this; }
        public Burst KeyUp(int vk) { Add(0x0101, (IntPtr)vk, unchecked((IntPtr)(int)0xC0000001)); return this; }
        /* WM_SYSKEYDOWN: GLFW reports it as a normal key, but the WM_SYSCHAR TranslateMessage makes of it
           does not reach ImGui - a plain WM_KEYDOWN of a letter would also type that letter */
        public Burst ShortcutKey(int vk)
        {
            Add(0x0104, (IntPtr)vk, (IntPtr)1);
            Add(0x0105, (IntPtr)vk, unchecked((IntPtr)(int)0xC0000001));
            return this;
        }
        public Burst Char(char c) { Add(0x0102, (IntPtr)c, (IntPtr)1); return this; }
        public Burst Break(int count) { for (int i = 0; i < count; i++) Key(0x87 /*VK_F24*/); return this; }
        public Burst Wheel(int screenX, int screenY, int delta)
        {
            Add(0x020A, (IntPtr)((delta << 16) | (buttons & 0xFFFF)), LP(screenX, screenY));
            return this;
        }

        static int Mask(int b) { return b == 0 ? 0x0001 : b == 1 ? 0x0002 : 0x0010; }
        static uint DownMsg(int b) { return b == 0 ? 0x0201u : b == 1 ? 0x0204u : 0x0207u; }
        static uint UpMsg(int b) { return b == 0 ? 0x0202u : b == 1 ? 0x0205u : 0x0208u; }

        public void Send()
        {
            uint pid; uint tid = GetWindowThreadProcessId(hwnd, out pid);
            IntPtr th = OpenThread(0x0002 /*THREAD_SUSPEND_RESUME*/, false, tid);
            if (th != IntPtr.Zero) SuspendThread(th);
            try { for (int i = 0; i < msgs.Count; i++) PostMessage(hwnd, msgs[i], wps[i], lps[i]); }
            finally { if (th != IntPtr.Zero) { ResumeThread(th); CloseHandle(th); } }
        }
    }
}
"@
}

# ---------------------------------------------------------------- instance

function Get-ShotStatePath { Join-Path $script:ShotWorkDir "state.json" }

<#
.SYNOPSIS Starts an isolated MCUViewer instance for screenshots and opens the given project.
.PARAMETER LicensePath  License file to load; defaults to the one in the user's MCUViewer config.
#>
function Start-ShotInstance([string]$Project, [string]$LicensePath = "") {
    # the log directory shown in Settings -> General lives here, so it is kept short and tidy
    $appdata = Join-Path $env:LOCALAPPDATA "MCUViewer-docs"
    $cfgDir = Join-Path $appdata "MCUViewer"
    New-Item -ItemType Directory -Force $cfgDir, $script:ShotWorkDir | Out-Null
    $userCfg = Join-Path $env:APPDATA "MCUViewer\config.json"
    $cfg = Get-Content $userCfg -Raw | ConvertFrom-Json
    $cfg.projects.recent = @()
    $cfg.projects.auto_save = $true
    $cfg.eula.accepted = $true
    $cfg.license.auto_take_seat = $false
    if ($LicensePath) { $cfg.license.path = $LicensePath }
    ($cfg | ConvertTo-Json -Depth 10) | Out-File -Encoding ascii (Join-Path $cfgDir "config.json")
    $bundle = Join-Path $env:APPDATA "MCUViewer\ca_bundle.pem"
    if (Test-Path $bundle) { Copy-Item $bundle $cfgDir -Force }

    $savedAppData = $env:APPDATA
    $env:APPDATA = $appdata
    try { $p = Start-Process -FilePath $script:ShotExe -ArgumentList "`"$Project`"" -PassThru }
    finally { $env:APPDATA = $savedAppData }

    $h = [IntPtr]::Zero
    for ($i = 0; $i -lt 60 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 500; $h = [ShotNative]::FindMainWindow([uint32]$p.Id) }
    if ($h -eq [IntPtr]::Zero) { throw "MCUViewer window did not appear" }
    Start-Sleep -Seconds 2
    # outside of every monitor, so that the real cursor never hovers it
    [ShotNative]::SetFrame($h, 4000, 100, $script:ShotWidth, $script:ShotHeight)
    $script:ShotHwnd = $h; $script:ShotPid = $p.Id

    $port = 0
    for ($i = 0; $i -lt 20 -and $port -eq 0; $i++) {
        Start-Sleep -Milliseconds 500
        $c = Get-NetTCPConnection -State Listen -OwningProcess $p.Id -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($c) { $port = $c.LocalPort }
    }
    @{ pid = $p.Id; port = $port } | ConvertTo-Json | Out-File -Encoding ascii (Get-ShotStatePath)
    Connect-Mcp $port | Out-Null
    "MCUViewer pid=$($p.Id) mcp port=$port title=$([ShotNative]::Title($h))"
}

<# .SYNOPSIS Attaches to the instance started by Start-ShotInstance (every script runs in a new process). #>
function Use-ShotInstance {
    $state = Get-Content (Get-ShotStatePath) -Raw | ConvertFrom-Json
    $script:ShotPid = [int]$state.pid
    $script:ShotHwnd = [ShotNative]::FindMainWindow([uint32]$state.pid)
    if ($script:ShotHwnd -eq [IntPtr]::Zero) { throw "Screenshot instance (pid $($state.pid)) is not running" }
    Restore-ShotWindow
    Connect-Mcp ([int]$state.port) | Out-Null
}

<# .SYNOPSIS Puts the window back to its off-screen place and size, e.g. after Win+D minimized it. #>
function Restore-ShotWindow {
    $f = [ShotNative]::FrameBounds($script:ShotHwnd)
    if ([ShotNative]::IsIconic($script:ShotHwnd) -or ($f.Right - $f.Left) -ne $script:ShotWidth -or ($f.Bottom - $f.Top) -ne $script:ShotHeight -or $f.Left -ne 4000) {
        [ShotNative]::SetFrame($script:ShotHwnd, 4000, 100, $script:ShotWidth, $script:ShotHeight)
        Start-Sleep -Milliseconds 800
    }
}

function Stop-ShotInstance {
    if ($script:ShotHwnd -ne [IntPtr]::Zero) { [ShotNative]::PostMessage($script:ShotHwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null }
    Start-Sleep -Seconds 3
    if (Get-Process -Id $script:ShotPid -ErrorAction SilentlyContinue) { "still running - a dialog may be open" } else { "closed" }
}

# ---------------------------------------------------------------- input (screenshot coordinates)

function New-ShotBurst { New-Object ShotNative+Burst $script:ShotHwnd }
function ConvertTo-Client([int]$X, [int]$Y) { $o = [ShotNative]::ClientOffset($script:ShotHwnd); return @(($X - $o.X), ($Y - $o.Y)) }

<#
.SYNOPSIS Clicks at screenshot coordinates. -Hold keeps the mouse there for about 2 frames per unit afterwards.
#>
function Invoke-ShotClick([int]$X, [int]$Y, [switch]$Right, [switch]$Double, [switch]$Slow, [int]$Hold = 0, [int]$WaitMs = 350) {
    $c = ConvertTo-Client $X $Y; $x = $c[0]; $y = $c[1]
    $btn = if ($Right) { 1 } else { 0 }
    $b = New-ShotBurst
    if ($Slow) {
        # hovers for a few frames before pressing and keeps the button down for a few more - dock tabs need it
        [void]$b.Move($x - 4, $y - 1).Break(1).Move($x, $y).Break(3).Down($x, $y, $btn).Break(2).Up($x, $y, $btn)
    }
    else {
        [void]$b.Move($x - 4, $y - 1).Break(1).Move($x, $y).Down($x, $y, $btn).Move($x, $y).Up($x, $y, $btn)
    }
    # no frame break here: unfocused, the app runs at 10 fps and ImGui needs both presses within 0.3 s
    if ($Double) { [void]$b.Down($x, $y, $btn).Move($x, $y).Up($x, $y, $btn) }
    [void]$b.Break($Hold)
    $b.Send()
    Start-Sleep -Milliseconds $WaitMs
}

<#
.SYNOPSIS Clicks a dock tab (e.g. "Var Viewer" at 50,70 or "Trace Viewer" at 139,70). Dock tabs only switch when the
          button stays down over several real frames, so the press and the release are sent 0.4 s apart.
#>
function Invoke-ShotTabClick([int]$X, [int]$Y, [int]$WaitMs = 1500) {
    $c = ConvertTo-Client $X $Y
    $b = New-ShotBurst; [void]$b.Move($c[0] - 4, $c[1] - 1).Break(1).Move($c[0], $c[1]).Break(2).Down($c[0], $c[1], 0); $b.Send()
    Start-Sleep -Milliseconds 400
    $b = New-ShotBurst; [void]$b.Move($c[0], $c[1]).Up($c[0], $c[1], 0); $b.Send()
    Start-Sleep -Milliseconds $WaitMs
}

<# .SYNOPSIS True while the Var Viewer tab is shown - its blue "Import variables" button is at 99,152. #>
function Test-ShotVarViewerShown { $c = Get-ShotPixel 40 152; return ($c[2] -gt 100 -and $c[2] -gt $c[0] + 50) }

function Show-ShotVarViewer {
    for ($i = 0; $i -lt 4 -and -not (Test-ShotVarViewerShown); $i++) { Invoke-ShotTabClick 50 70 }
    if (-not (Test-ShotVarViewerShown)) { throw "could not switch to Var Viewer" }
}

function Show-ShotTraceViewer {
    for ($i = 0; $i -lt 4 -and (Test-ShotVarViewerShown); $i++) { Invoke-ShotTabClick 139 70 }
    if (Test-ShotVarViewerShown) { throw "could not switch to Trace Viewer" }
}

<#
.SYNOPSIS Clicks until $Check returns true (up to 3 times) - for clicks that may get lost while the GUI is busy.
#>
function Invoke-ShotClickUntil([int]$X, [int]$Y, [scriptblock]$Check, [switch]$Double, [switch]$Right) {
    for ($i = 0; $i -lt 3; $i++) {
        Invoke-ShotClick $X $Y -Double:$Double -Right:$Right -WaitMs 500
        if (& $Check) { return }
    }
    throw "click at $X,$Y did not reach the expected state"
}

<# .SYNOPSIS Moves the mouse to screenshot coordinates and keeps it there (tooltips need about 40). #>
function Invoke-ShotHover([int]$X, [int]$Y, [int]$Hold = 4, [int]$WaitMs = 200) {
    $c = ConvertTo-Client $X $Y; $x = $c[0]; $y = $c[1]
    $b = New-ShotBurst
    [void]$b.Move($x - 4, $y - 1).Break(1).Move($x, $y).Break($Hold)
    $b.Send()
    Start-Sleep -Milliseconds $WaitMs
}

<#
.SYNOPSIS Drags with the left button. -NoRelease leaves the button down (for capturing a drag in progress;
          the mouse stays at the end point for -Hold units) - finish it with Complete-ShotDrag.
#>
function Invoke-ShotDrag([int]$X0, [int]$Y0, [int]$X1, [int]$Y1, [int]$Steps = 10, [switch]$NoRelease, [int]$Hold = 4, [int]$WaitMs = 300, [int]$Button = 0) {
    $c0 = ConvertTo-Client $X0 $Y0; $c1 = ConvertTo-Client $X1 $Y1
    $b = New-ShotBurst
    [void]$b.Move($c0[0] - 4, $c0[1] - 1).Break(1).Move($c0[0], $c0[1]).Down($c0[0], $c0[1], $Button).Break(1)
    for ($i = 1; $i -le $Steps; $i++) {
        $x = [int]($c0[0] + ($c1[0] - $c0[0]) * $i / $Steps); $y = [int]($c0[1] + ($c1[1] - $c0[1]) * $i / $Steps)
        [void]$b.Move($x, $y).Break(1)
    }
    [void]$b.Break($Hold)
    if (-not $NoRelease) { [void]$b.Move($c1[0], $c1[1]).Up($c1[0], $c1[1], $Button) }
    $b.Send()
    Start-Sleep -Milliseconds $WaitMs
}

function Complete-ShotDrag([int]$X, [int]$Y, [int]$Button = 0) {
    $c = ConvertTo-Client $X $Y
    $b = New-ShotBurst
    [void]$b.Move($c[0], $c[1]).Break(1).Move($c[0], $c[1]).Up($c[0], $c[1], $Button)
    $b.Send()
    Start-Sleep -Milliseconds 300
}

<# .SYNOPSIS Mouse wheel at screenshot coordinates; positive notches zoom in on plots. #>
function Invoke-ShotWheel([int]$X, [int]$Y, [int]$Notches = 1, [int]$WaitMs = 300) {
    $c = ConvertTo-Client $X $Y
    $o = [ShotNative]::FrameOrigin($script:ShotHwnd)
    $b = New-ShotBurst
    [void]$b.Move($c[0] - 4, $c[1] - 1).Break(1).Move($c[0], $c[1]).Break(1)
    $d = if ($Notches -ge 0) { 120 } else { -120 }
    for ($i = 0; $i -lt [Math]::Abs($Notches); $i++) { [void]$b.Wheel($o.X + $X, $o.Y + $Y, $d).Break(1) }
    $b.Send()
    Start-Sleep -Milliseconds $WaitMs
}

<# .SYNOPSIS Types text into the focused ImGui input field. #>
function Send-ShotText([string]$Text, [switch]$Enter) {
    $b = New-ShotBurst
    foreach ($ch in $Text.ToCharArray()) { [void]$b.Char($ch) }
    if ($Enter) { [void]$b.Break(1).Key(0x0D) }
    $b.Send()
    Start-Sleep -Milliseconds 300
}

<#
.SYNOPSIS Replaces the content of the active input field (Ctrl+A, then the text). Note: when idle the app runs only a
          few frames per second and ImGui takes one key change per frame, so long key sequences are slow.
#>
function Set-ShotFieldText([string]$Text) {
    $b = New-ShotBurst
    [void]$b.KeyDown(0x11).ShortcutKey(0x41).KeyUp(0x11)
    foreach ($ch in $Text.ToCharArray()) { [void]$b.Char($ch) }
    $b.Send()
    Start-Sleep -Milliseconds 1500
}

function Send-ShotKey([int]$Vk, [int]$Times = 1) {
    $b = New-ShotBurst
    for ($i = 0; $i -lt $Times; $i++) { [void]$b.Key($Vk) }
    $b.Send()
    Start-Sleep -Milliseconds 250
}

<#
.SYNOPSIS Makes sure "new group0" of the example project is expanded in the plot group tree.
          A single click on the tree arrow does not register through window messages - a double click on the label does.
#>
function Expand-ShotGroup0 {
    for ($i = 0; $i -lt 3 -and -not (Test-ShotPixelLit 48 695); $i++) { Invoke-ShotClick 106 669 -Double -WaitMs 600 }
    if (-not (Test-ShotPixelLit 48 695)) { throw "could not expand new group0" }
}

<# .SYNOPSIS Opens Options -> Acquisition (the probe list is refreshed when it opens, so it waits a bit). #>
<# .SYNOPSIS True while the menu bar header at X shows the blue "open" highlight. #>
function Test-ShotMenuOpen([int]$X) { $c = Get-ShotPixel $X 36; return ($c[2] -gt $c[0] + 30) }

<# .SYNOPSIS Opens a menu of the main menu bar (header at screenshot X), clicking only while it is closed. #>
function Open-ShotMenu([int]$X) {
    for ($i = 0; $i -lt 3 -and -not (Test-ShotMenuOpen ($X - 20)); $i++) { Invoke-ShotClick $X 42 -WaitMs 500 }
    if (-not (Test-ShotMenuOpen ($X - 20))) { throw "menu at $X did not open" }
}

<# .SYNOPSIS Opens Options -> Acquisition (the probe list is refreshed when it opens, so it waits a bit). #>
function Open-ShotAcquisitionSettings {
    Open-ShotMenu 76
    Invoke-ShotClick 81 66 -WaitMs 1500
}

<# .SYNOPSIS Opens Options -> Flashing. #>
function Open-ShotFlashingSettings {
    Open-ShotMenu 76
    Invoke-ShotClick 73 86 -WaitMs 800
}

<# .SYNOPSIS Opens Settings -> General. #>
function Open-ShotGeneralSettings {
    Open-ShotMenu 140
    Invoke-ShotClick 150 66 -WaitMs 800
}

<#
.SYNOPSIS Opens the Variable Edit window by double-clicking a variable table row (screenshot y of the row).
          The name field gets keyboard focus with a nav frame when the window opens - a click inside clears it.
#>
function Open-ShotVariableEdit([int]$RowY) {
    Invoke-ShotClick 100 $RowY -Double -WaitMs 900
    Invoke-ShotClick 660 760 -WaitMs 500
    Clear-ShotHover
}

<#
.SYNOPSIS Closes the open modal window with Escape (every settings window closes on it). Escape leaves a keyboard
          nav frame on the last focused item, so a click on the status bar follows to hide it.
#>
function Close-ShotDialog {
    Send-ShotKey 0x1B
    Start-Sleep -Milliseconds 300
    Invoke-ShotClick 300 1020 -WaitMs 300
    Clear-ShotHover
}

<# .SYNOPSIS Moves the ImGui mouse away from every widget, so nothing is drawn hovered. #>
function Clear-ShotHover { Invoke-ShotHover 1320 1028 -Hold 2 }

# ---------------------------------------------------------------- capture

<#
.SYNOPSIS Captures the window into raw/<Name>.png. -Crop x,y,w,h keeps only a part of it (e.g. a dialog).
#>
function Save-Shot([string]$Name, [int[]]$Crop = $null, [switch]$FromFile) {
    New-Item -ItemType Directory -Force $script:ShotRawDir | Out-Null
    $path = Join-Path $script:ShotRawDir "$Name.png"
    if (-not $FromFile) {
        $f = [ShotNative]::FrameBounds($script:ShotHwnd)
        if (($f.Right - $f.Left) -ne $script:ShotWidth -or ($f.Bottom - $f.Top) -ne $script:ShotHeight) { throw "Window is not ${script:ShotWidth}x${script:ShotHeight} - was it minimized? Run Restore-ShotWindow and repeat the shot." }
        [ShotNative]::Capture($script:ShotHwnd, $path)
    }
    if ($Crop) {
        $full = [System.Drawing.Bitmap]::FromFile($path)
        try { $part = $full.Clone((New-Object System.Drawing.Rectangle $Crop[0], $Crop[1], $Crop[2], $Crop[3]), $full.PixelFormat) }
        finally { $full.Dispose() }
        $part.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $part.Dispose()
    }
    return $path
}

<#
.SYNOPSIS Overwrites a part of a raw screenshot (e.g. the Hardware ID of this computer) with a solid color and an
          optional placeholder text. Done on the PNG itself, because the .drawio files embed the raw image.
#>
function Hide-ShotRegion([string]$Name, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Color = "#233550", [string]$Text = "") {
    $path = Join-Path $script:ShotRawDir "$Name.png"
    $src = [System.Drawing.Bitmap]::FromFile($path)
    $bmp = New-Object System.Drawing.Bitmap $src
    $src.Dispose()
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($Color))), $X, $Y, $W, $H)
    if ($Text) {
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $font = New-Object System.Drawing.Font "Segoe UI", 10
        $g.DrawString($Text, $font, [System.Drawing.Brushes]::Gainsboro, $X + 3, $Y + 1)
    }
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

<# .SYNOPSIS Returns the color of a screenshot pixel as [r, g, b] - for checking the UI state before a shot. #>
function Get-ShotPixel([int]$X, [int]$Y) {
    $tmp = Join-Path $script:ShotWorkDir "pixel.png"
    [ShotNative]::Capture($script:ShotHwnd, $tmp)
    $b = [System.Drawing.Bitmap]::FromFile($tmp)
    try { $c = $b.GetPixel($X, $Y); return @([int]$c.R, [int]$c.G, [int]$c.B) } finally { $b.Dispose() }
}

<#
.SYNOPSIS Repeats $Action (e.g. a hover) until the pixel at X,Y satisfies $Test, then captures - for states that last
          only a few frames, like a hover highlight. $Test gets the [r, g, b] array.
#>
function Save-ShotWhen([string]$Name, [int]$X, [int]$Y, [scriptblock]$Test, [scriptblock]$Action, [int[]]$Crop = $null) {
    $last = $null
    for ($i = 0; $i -lt 5; $i++) {
        & $Action
        for ($j = 0; $j -lt 10; $j++) {
            # the pixel is checked on the captured image itself, so the state cannot change in between
            $path = Save-Shot $Name
            $b = [System.Drawing.Bitmap]::FromFile($path)
            try { $c = $b.GetPixel($X, $Y); $last = @([int]$c.R, [int]$c.G, [int]$c.B) } finally { $b.Dispose() }
            if (& $Test $last) { return Save-Shot $Name -Crop $Crop -FromFile }
            Start-Sleep -Milliseconds 80
        }
    }
    throw "state for $Name not reached (pixel $X,$Y = $($last -join ','))"
}

<# .SYNOPSIS True for the blue ImGui highlight of a hovered/selected item. #>
function Test-ShotBlue($c) { return ($c[2] -gt 150 -and $c[2] -gt $c[0] + 60) }

<# .SYNOPSIS True when the checkbox centered at X,Y shows its (light blue) check mark. #>
function Test-ShotChecked([int]$X, [int]$Y) {
    $tmp = Join-Path $script:ShotWorkDir "pixel.png"
    [ShotNative]::Capture($script:ShotHwnd, $tmp)
    $b = [System.Drawing.Bitmap]::FromFile($tmp)
    try {
        for ($dx = -6; $dx -le 6; $dx += 2) { for ($dy = -6; $dy -le 6; $dy += 2) {
            $c = $b.GetPixel($X + $dx, $Y + $dy)
            if ($c.B -gt 200 -and $c.G -gt 120 -and $c.R -lt 120) { return $true }
        } }
        return $false
    } finally { $b.Dispose() }
}

<# .SYNOPSIS Clicks a checkbox until it has the wanted state. #>
function Set-ShotCheckbox([int]$X, [int]$Y, [bool]$Checked) {
    for ($i = 0; $i -lt 3 -and (Test-ShotChecked $X $Y) -ne $Checked; $i++) { Invoke-ShotClick $X $Y -WaitMs 700 }
    if ((Test-ShotChecked $X $Y) -ne $Checked) { throw "checkbox at $X,$Y did not change" }
}

<# .SYNOPSIS True when the pixel is brighter than the dark window background, e.g. a checked box or a highlighted row. #>
function Test-ShotPixelLit([int]$X, [int]$Y) { $c = Get-ShotPixel $X $Y; return (($c[0] + $c[1] + $c[2]) -gt 150) }

<#
.SYNOPSIS Captures a sequence of frames for an animated GIF and encodes it with ffmpeg.
.PARAMETER Width  Width of the GIF in pixels (the docs show images at 1000 px).
#>
function Save-ShotGif([string]$OutPath, [double]$Seconds = 6, [int]$Fps = 12, [int]$Width = 1000, [hashtable]$Actions = @{}) {
    $dir = Join-Path $script:ShotWorkDir "gif"
    if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
    New-Item -ItemType Directory -Force $dir | Out-Null
    $frames = [int]($Seconds * $Fps); $period = 1000.0 / $Fps
    # $Actions: @{ 2.5 = { ... } } runs the script block once the recording reaches that second
    $pending = [System.Collections.ArrayList]@($Actions.Keys | Sort-Object)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $frames; $i++) {
        while ($pending.Count -gt 0 -and $sw.ElapsedMilliseconds -ge [double]$pending[0] * 1000) { & $Actions[$pending[0]] | Out-Null; $pending.RemoveAt(0) }
        [ShotNative]::Capture($script:ShotHwnd, (Join-Path $dir ("f{0:D4}.png" -f $i)))
        $wait = [int](($i + 1) * $period - $sw.ElapsedMilliseconds)
        if ($wait -gt 0) { Start-Sleep -Milliseconds $wait }
    }
    $realFps = [Math]::Round($frames / ($sw.ElapsedMilliseconds / 1000.0), 2)
    $filter = "scale=${Width}:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle"
    & ffmpeg -y -loglevel error -framerate $realFps -i (Join-Path $dir "f%04d.png") -filter_complex $filter -loop 0 $OutPath
    "gif: $OutPath ($frames frames, $realFps fps)"
}

# ---------------------------------------------------------------- annotation

<#
.SYNOPSIS Builds the annotated .drawio of a spec from specs/ and exports it to the PNG used by the docs.
#>
function Build-ShotAnnotation([string]$Spec) {
    $specPath = if ($Spec.EndsWith(".json")) { $Spec } else { Join-Path $script:ShotRoot "specs\$Spec.json" }
    $out = & python -I (Join-Path $script:ShotRoot "annotate.py") $specPath
    if ($LASTEXITCODE -ne 0) { throw "annotate.py failed: $out" }
    $drawio = ($out | Select-Object -Last 1).Trim()
    if ($drawio.EndsWith(".png")) { return $drawio }
    $png = [IO.Path]::ChangeExtension($drawio, ".png")
    # draw.io is an Electron app; the VS Code terminal sets ELECTRON_RUN_AS_NODE, which makes it start as plain node
    $saved = $env:ELECTRON_RUN_AS_NODE
    Remove-Item Env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
    try {
        $p = Start-Process -FilePath "C:\Program Files\draw.io\draw.io.exe" -ArgumentList "-x -f png -s 2 -o `"$png`" `"$drawio`"" -Wait -PassThru -WindowStyle Hidden
    } finally { if ($saved) { $env:ELECTRON_RUN_AS_NODE = $saved } }
    if ($p.ExitCode -ne 0) { throw "draw.io export failed ($($p.ExitCode))" }
    return $png
}

# ---------------------------------------------------------------- MCP (streamable HTTP, JSON-RPC)

function ConvertFrom-McpBody([string]$Body) {
    if ($Body -match '^\s*\{') { return $Body | ConvertFrom-Json }
    $data = ($Body -split "`n" | Where-Object { $_ -like 'data:*' } | ForEach-Object { $_.Substring(5).Trim() }) -join ''
    if ($data) { return $data | ConvertFrom-Json }
    return $null
}

function Connect-Mcp([int]$Port) {
    # the server listens on the IPv6 loopback
    $script:McpUrl = "http://[::1]:$Port/mcp"
    $body = @{ jsonrpc = '2.0'; id = 0; method = 'initialize'; params = @{ protocolVersion = '2025-03-26'; capabilities = @{}; clientInfo = @{ name = 'docs-shots'; version = '1.0' } } } | ConvertTo-Json -Depth 6 -Compress
    $r = Invoke-WebRequest -UseBasicParsing -Uri $script:McpUrl -Method Post -Body $body -ContentType 'application/json' -Headers @{ Accept = 'application/json, text/event-stream' }
    $script:McpSession = $r.Headers['Mcp-Session-Id']
    $hdr = @{ Accept = 'application/json, text/event-stream' }
    if ($script:McpSession) { $hdr['Mcp-Session-Id'] = $script:McpSession }
    $n = @{ jsonrpc = '2.0'; method = 'notifications/initialized' } | ConvertTo-Json -Compress
    try { Invoke-WebRequest -UseBasicParsing -Uri $script:McpUrl -Method Post -Body $n -ContentType 'application/json' -Headers $hdr | Out-Null } catch {}
    return ConvertFrom-McpBody $r.Content
}

function Invoke-Mcp([string]$Tool, [hashtable]$Arguments = @{}, [switch]$NoRetry) {
    # the server drops idle sessions - reconnect once and repeat the call
    if (-not $NoRetry) {
        try { return Invoke-Mcp $Tool $Arguments -NoRetry }
        catch { if ("$_" -notmatch 'Session not found') { throw }; Connect-Mcp ([int]($script:McpUrl -replace '.*:(\d+)/mcp$', '$1')) | Out-Null }
        return Invoke-Mcp $Tool $Arguments -NoRetry
    }
    $script:McpId++
    $hdr = @{ Accept = 'application/json, text/event-stream' }
    if ($script:McpSession) { $hdr['Mcp-Session-Id'] = $script:McpSession }
    $body = @{ jsonrpc = '2.0'; id = $script:McpId; method = 'tools/call'; params = @{ name = $Tool; arguments = $Arguments } } | ConvertTo-Json -Depth 8 -Compress
    $r = Invoke-WebRequest -UseBasicParsing -Uri $script:McpUrl -Method Post -Body $body -ContentType 'application/json' -Headers $hdr
    $j = ConvertFrom-McpBody $r.Content
    if ($j.result -and $j.result.content) { return ($j.result.content | ForEach-Object { $_.text }) -join "`n" }
    return ($j | ConvertTo-Json -Depth 8 -Compress)
}
