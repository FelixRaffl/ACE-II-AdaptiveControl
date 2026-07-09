# ESP32 Adaptive Control Model — Spezifikation

ESP32-Version des adaptiven DC-Motor-Reglers. **Validierter ESP32-Stand — Delta zur
Referenz in den Datei-Headern dokumentiert.** Nur die simulierte Strecke wird durch
**echte I/O** ersetzt. Läuft über **Simulink External Mode** (Monitor & Tune).

## Regler-Bausteine (validierter ESP32-Stand — Delta zur Referenz in den Datei-Headern dokumentiert)

| Block | Datei | Funktion |
|---|---|---|
| RLS-Schätzer | [`rls_estimator.m`](rls_estimator.m) | schätzt `[a0; b0]` online |
| Pol-Platzierung | [`pole_placement_controller.m`](pole_placement_controller.m) | `d0, d1` aus `a0,b0,q0,q1` |
| PI-Regler | [`PI_C.m`](PI_C.m) | `u = u_prev + d1·e + d0·e_prev` |

Parameter: `q0 = 0.06`, `q1 = -0.5`, `alpha = 0.98`, `P0 = 100·I`,
`x̂0 = [-0.5; 1.0]`, `b0Min = 1e-3`, **Sample-Time T = 0.08 s**
(gesamter Regelkreis).

## Signalfluss (T = 0.08 s diskret)

```
                 ω_ref (tunbar) ──(+)──► e_curr ─────────────────┐
                          ω(k) ──(−)──┘        e_prev = z⁻¹(e_curr)
                                                                  │
   y(k)=ω(k) ─┐                                                   ▼
   y_prev = z⁻¹(y)  ─► [RLS] ─► a0,b0 ─► [PolePlace q0,q1] ─► d0,d1 ─► [PI] ─► u
   u_prev = z⁻¹(u) ──────────────────────────────────────────────────────────┤
                                                                  u ──► Saturation[-255,255] ──► Aktuator
                                                                  (saturiertes u → z⁻¹ → u_prev)
```

## I/O-Mapping ESP32

### Ausgang: u → Motor
- `u` auf **[-255, 255]** saturieren.
- **Betrag** `|u|` → **PWM** auf **GPIO14** (LEDC). Die bestätigte PWM-Block-Range
  ist 0..255, daher wird `|u|` direkt verwendet.
- **Vorzeichen** `sign(u)` → **Richtung** (Digital Output):
  - `u ≥ 0`: IN1=1 (GPIO26), IN2=0 (GPIO27)
  - `u < 0`: IN1=0, IN2=1

### Eingang: Encoder → ω
- Quadratur-Counts `N` vom **`arduinosensorlib/Encoder`-Block** (Simulink Support
  Package for Arduino Hardware 25.2.9), GPIO32/GPIO33 (Encoder A/B). Der Block arbeitet
  interrupt-basiert mit ×4-Quadratur, liefert `int32` und läuft im Mode 'No reset'.
  Für die Demo-Drehzahlen ist das ausreichend. ESP32-PCNT via `coder.ceval` bleibt
  bei Count-Verlust eine Zukunftsoption.
- `ΔN = N(k) − N(k−1)` (Unit Delay + Subtraktion).
- `ω(k) = 2π · ΔN / (T · CPR)`, **CPR ≈ 44** (11 PPR ×4), im Lab nachmessen.
- `y(k) = ω(k)`.

> ⚠️ `ω_ref` in **derselben Einheit** wie `ω` (rad/s). RLS adaptiert die realen `a0,b0`
> (Einheiten u[counts]→ω[rad/s]) automatisch — deshalb kein manuelles Tuning der Streckenverstärkung.

## External Mode / Scopes

Live mitschreiben/tunen: `ω`, `ω_ref`, `u`, `e`, `a0_est`, `b0_est`.
`ω_ref` als **tunbaren Constant/Slider**. Demo: Schwungscheibe **S → L** wechseln → `a0,b0`
adaptieren sich, Einschwingen bleibt ~250 ms.

## Build-Reihenfolge (inkrementell — nicht alles auf einmal!)

1. **PWM open-loop**: nur `Constant(duty) → PWM GPIO14` + Richtung. Oszi an GPIO14, Duty live
   tunen. ✓ Aktuator.
2. **Encoder open-loop**: Encoder-Block → ΔN → ω → Scope. Welle von Hand/Motor drehen.
   ✓ Sensor + CPR.
3. **Regelkreis schließen**: RLS + PolePlace + PI dazwischen, Unit Delays, Saturation, ω_ref.
   Strombegrenzung am Netzteil aktiv lassen, ω_ref langsam hochfahren.

## Offene Punkte

1. **CPR-Diskrepanz:** Raffls Modell nutzt Gain `2π/11`, unsere Annahme ist
   CPR ≈ 44 (11 PPR × 4) → Faktor 4. Per 1-Umdrehungs-Test klären (TESTPLAN Stufe 2),
   nicht raten.
2. Min-Duty/Deadband gegen Haftreibung evtl. ergänzen (unverändert offen).

Pin-Quelle: Raffls am Board getestetes Modell (2026-07-06).
