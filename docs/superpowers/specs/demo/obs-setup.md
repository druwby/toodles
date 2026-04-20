# OBS Studio Setup

Install once. Configure once. Record all gameplay scenes in one Day 2 sitting.

## Install (5 min)

1. Download from `obsproject.com/download` (Windows installer)
2. Run installer, accept defaults
3. First-run wizard → **Optimize for recording**, 1920×1080, 60 FPS

## Settings → Output (2 min)

- Output Mode: **Advanced**
- Recording Path: `C:\Users\riven\Desktop\491project\_demo-recording\raw\` (create this folder first)
- Recording Format: **MP4**
- Encoder: **x264** if CPU is decent, or **NVENC H.264** if you have an NVIDIA GPU
- Rate Control: **CBR**, Bitrate **12000 Kbps**
- Keyframe Interval: 2

## Settings → Video (1 min)

- Base (Canvas) Resolution: **1920×1080**
- Output (Scaled) Resolution: **1920×1080**
- Common FPS Values: **60**

## Settings → Audio (1 min)

- Mic/Aux: **Disabled** (voice-over is separate in Audacity)
- Desktop Audio: **Disabled** (we don't want Appetize chirps or system sounds)

## Settings → Hotkeys (1 min)

- Start Recording: **Ctrl+F9**
- Stop Recording: **Ctrl+F10**
- Pause Recording: **Ctrl+F11**

These work globally — you can start/stop without clicking back to OBS.

## Scene setup (3 min)

1. Sources panel → **+** → **Display Capture** → name it "Full Screen"
2. Select your primary monitor
3. Scene should show your whole desktop in OBS preview

You'll crop the final framing in CapCut, not here. That keeps takes flexible if you reposition Chrome windows later.

## Rehearsal before real recording

1. Open the two Appetize Chrome windows (see `appetize-setup.md`)
2. Arrange side-by-side on screen
3. Press **Ctrl+F9** — red dot appears top-right of OBS
4. Run through Scene 5 once
5. **Ctrl+F10** to stop
6. Open the MP4 in the recording folder — verify clean capture, no black frames
7. If window borders or browser chrome are visible, adjust window positions and rehearse again

## Naming convention

OBS names files with timestamps by default. **Rename each take manually after recording:**
- `scene03_take01.mp4`
- `scene03_take02.mp4`
- `scene05_split_take01.mp4`

Use `recording-checklist.md` to track which take is which. This is the single thing that saves you the most time in CapCut.

## Common gotchas

- **Cursor visible in recording:** normal. OBS captures the cursor. In CapCut you can't easily remove it — so move the cursor off-screen before each take.
- **Laggy recording:** drop bitrate to 8000 Kbps or switch encoder to NVENC if you have a GPU.
- **Red dot overlay:** not recorded. Only you see it.
- **Recording doesn't start:** check disk space. OBS silently fails if drive is nearly full.
