"""
Hardware block diagram - Adaptive Control DC Motor (Prototyp-Topologie)
Run:    python draw_hardware.py
Output: img/hardware.png

Topologie: ESP32 per USB (Power + Serial), 12V Netzteil -> L298N VM, gemeinsame Masse.
Drahtfarben Motor/Encoder: Rot=M+, Weiss=M-, Blau=EncVCC, Schwarz=EncGND, Gelb=A, Gruen=B.
"""

import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch

BASE = os.path.dirname(os.path.abspath(__file__))
OUT  = os.path.join(BASE, "img", "hardware.png")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

# -- Colors -----------------------------------------------------------------
C_ORANGE = "#E67E22"   # power supply (12V)
C_GREEN  = "#1E8449"   # motor drive
C_BLUE   = "#2471A3"   # control signals (ESP32 -> L298N)
C_PURPLE = "#7D3C98"   # encoder feedback
C_SLATE  = "#566573"   # USB (power + serial)
C_ESP    = "#2C6FAD"
C_RED    = "#C0392B"
C_TEAL   = "#148F77"
C_DTEAL  = "#0E6655"
C_GRAY   = "#7F8C8D"
C_MCI    = "#00204B"

fig, ax = plt.subplots(figsize=(18, 10))
ax.set_xlim(0, 18)
ax.set_ylim(0, 10)
ax.axis("off")
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

# -- Block coordinates (cx, cy, w, h) ---------------------------------------
BW, BH = 2.2, 1.1

PC    = (2.3,  7.6, BW,  BH)        # top-left
ESP   = (13.2, 7.6, 2.7, 1.6)       # top-right
PSU   = (2.3,  3.4, BW,  BH)        # bottom-left
L298  = (6.1,  3.4, BW,  BH)
MOTOR = (9.9,  3.4, BW,  1.7)
FWS   = (12.9, 4.3, 1.8, 0.9)
FWL   = (15.0, 4.3, 1.8, 0.9)


def draw_block(cx, cy, w, h, lines, color, fs=11):
    rect = FancyBboxPatch((cx - w/2, cy - h/2), w, h,
                          boxstyle="round,pad=0.12",
                          facecolor=color, edgecolor="white",
                          linewidth=2.5, zorder=3)
    ax.add_patch(rect)
    n = len(lines)
    for i, (txt, bold) in enumerate(lines):
        dy = ((n - 1) / 2 - i) * (h / (n + 0.5))
        ax.text(cx, cy + dy, txt, ha="center", va="center",
                fontsize=fs, color="white",
                fontweight="bold" if bold else "normal", zorder=4)


def draw_arrow(x1, y1, x2, y2, label="", color=C_GRAY, lw=2.4,
               style="arc3,rad=0", offset=(0, 0.20), fs=9):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="-|>", color=color, lw=lw,
                                mutation_scale=20, connectionstyle=style),
                zorder=2)
    if label:
        mx = (x1 + x2) / 2 + offset[0]
        my = (y1 + y2) / 2 + offset[1]
        ax.text(mx, my, label, ha="center", va="bottom",
                fontsize=fs, color=color,
                bbox=dict(boxstyle="round,pad=0.2", fc="white",
                          ec="none", alpha=0.9), zorder=5)


def label_box(x, y, txt, color, fs=9):
    ax.text(x, y, txt, ha="center", va="center", fontsize=fs, color=color,
            bbox=dict(boxstyle="round,pad=0.3", fc="white", ec=color,
                      linewidth=1.2, alpha=0.97), zorder=5)


# -- Blocks -----------------------------------------------------------------
draw_block(*PC,    [("PC / Laptop", True), ("Simulink External Mode", False)], C_SLATE, fs=10)
draw_block(*ESP,   [("ESP32-WROOM-32", True), ("LEDC PWM", False),
                    ("Encoder-Interrupts", False)],                            C_ESP,  fs=10)
draw_block(*PSU,   [("Labornetzteil", True), ("12V (strombegrenzt)", False)],  C_ORANGE)
draw_block(*L298,  [("L298N", True), ("H-Bruecke", False)],                    C_GREEN)
draw_block(*MOTOR, [("DC Motor", True), ("Hyuduo 25GA371", False),
                    ("+ Encoder", False)],                                     C_PURPLE, fs=10)
draw_block(*FWS,   [("Schwung S", True), ("O 60 mm", False)],                  C_TEAL,  fs=9)
draw_block(*FWL,   [("Schwung L", True), ("O 120 mm", False)],                 C_DTEAL, fs=9)

# -- USB: PC -> ESP32 (top row) ---------------------------------------------
draw_arrow(PC[0]+PC[2]/2, PC[1], ESP[0]-ESP[2]/2, ESP[1],
           "USB  (Power + Serial)", C_SLATE)

# -- Power: PSU -> L298N (12V) ----------------------------------------------
draw_arrow(PSU[0]+PSU[2]/2, PSU[1], L298[0]-L298[2]/2, L298[1],
           "12V", C_ORANGE)

# -- Motor drive: L298N -> Motor (~8V, rot/weiss) ---------------------------
draw_arrow(L298[0]+L298[2]/2, L298[1], MOTOR[0]-MOTOR[2]/2, MOTOR[1],
           "~8V  (rot/weiss)", C_GREEN)

# -- Control: ESP32 -> L298N (ENA/IN1/IN2) ----------------------------------
ax.annotate("", xy=(L298[0], L298[1]+L298[3]/2),
            xytext=(ESP[0]-0.5, ESP[1]-ESP[3]/2),
            arrowprops=dict(arrowstyle="-|>", color=C_BLUE, lw=2.4,
                            mutation_scale=20,
                            connectionstyle="angle,angleA=0,angleB=90,rad=10"),
            zorder=2)
label_box(8.6, 5.9,
          "GPIO14 -> ENA  (PWM)\nGPIO26/27 -> IN1/IN2  (Richtung)",
          C_BLUE)

# -- Encoder: Motor -> ESP32 (gelb/gruen/blau/schwarz) ----------------------
ax.annotate("", xy=(ESP[0]+0.4, ESP[1]-ESP[3]/2),
            xytext=(MOTOR[0]+MOTOR[2]/2, MOTOR[1]+MOTOR[3]/2-0.3),
            arrowprops=dict(arrowstyle="-|>", color=C_PURPLE, lw=2.4,
                            mutation_scale=20,
                            connectionstyle="angle,angleA=90,angleB=0,rad=10"),
            zorder=2)
label_box(12.0, 6.2,
          "GPIO32 <- A (gelb)\nGPIO33 <- B (gruen)\n3.3V (blau) / GND (schwarz)",
          C_PURPLE)

# -- Mechanical shaft: Motor -> Flywheels -----------------------------------
draw_arrow(MOTOR[0]+MOTOR[2]/2, MOTOR[1]+0.25, FWS[0]-FWS[2]/2, FWS[1],
           "Welle", C_GRAY, lw=2.0, offset=(0.4, 0.12), fs=8.5)
draw_arrow(MOTOR[0]+MOTOR[2]/2, MOTOR[1]-0.25, FWL[0]-FWL[2]/2, FWL[1]-0.1,
           "", C_GRAY, lw=2.0)

# -- GND common rail (dashed) -----------------------------------------------
gnd_y = 2.1
for bx in (PSU, L298):
    ax.plot([bx[0], bx[0]], [bx[1]-bx[3]/2, gnd_y], color=C_GRAY, lw=1.5, ls="--", zorder=2)
ax.plot([PSU[0], ESP[0]], [gnd_y, gnd_y], color=C_GRAY, lw=1.5, ls="--", zorder=2)
ax.plot([ESP[0], ESP[0]], [gnd_y, ESP[1]-ESP[3]/2], color=C_GRAY, lw=1.5, ls="--", zorder=2)
ax.text((PSU[0]+L298[0])/2, gnd_y-0.22, "GND (gemeinsame Masse)",
        ha="center", va="top", fontsize=8.5, color=C_GRAY)

# -- Section backgrounds ----------------------------------------------------
def section_bg(x0, y0, x1, y1, label, color):
    rect = mpatches.FancyBboxPatch((x0, y0), x1-x0, y1-y0,
                                   boxstyle="round,pad=0.2",
                                   facecolor=color, edgecolor=color,
                                   alpha=0.07, linewidth=1.5,
                                   linestyle="--", zorder=1)
    ax.add_patch(rect)
    if label:
        ax.text((x0+x1)/2, y1+0.13, label, ha="center", va="bottom",
                fontsize=9, color=color, style="italic")

section_bg(0.5, 2.6, 11.2, 4.9, "Antriebs-/Leistungspfad", C_GREEN)
section_bg(11.4, 3.7, 16.0, 5.3, "Schwungscheiben (Plexiglas)", C_TEAL)

# -- Title ------------------------------------------------------------------
ax.text(9, 9.5, "Hardware-Schaltplan - Adaptive Control of a DC Motor",
        ha="center", va="center", fontsize=15, fontweight="bold", color=C_MCI)
ax.text(9, 9.1, "ESP32 (USB)  |  L298N H-Bruecke  |  Hyuduo 25GA371  |  12V Labornetzteil",
        ha="center", va="center", fontsize=10, color=C_GRAY)

# -- Legend -----------------------------------------------------------------
legend_items = [
    mpatches.Patch(color=C_SLATE,  label="USB (Power + Serial)"),
    mpatches.Patch(color=C_ORANGE, label="Versorgung 12V"),
    mpatches.Patch(color=C_GREEN,  label="Motoransteuerung"),
    mpatches.Patch(color=C_BLUE,   label="Steuersignale (ESP32)"),
    mpatches.Patch(color=C_PURPLE, label="Encoder-Feedback"),
]
ax.legend(handles=legend_items, loc="lower right", fontsize=9,
          framealpha=0.95, edgecolor="#cccccc", bbox_to_anchor=(0.99, 0.01))

fig.savefig(OUT, dpi=180, bbox_inches="tight", facecolor="white")
plt.close(fig)
print(f"Saved: {OUT}")
