# Hardware-Diagramm – Adaptive Control DC Motor

> **Schaltplan:** gerendert in `img/hardware.png` (aus `draw_hardware.py`).
> **Editierbare Version:** [`schaltplan.drawio`](schaltplan.drawio) — in VS Code mit der
> Extension „Draw.io Integration" (`hediet.vscode-drawio`) öffnen/bearbeiten.
> **Pin-Referenz (WireViz):** `img/wiring.png` aus [`wiring.yml`](wiring.yml) — exakte
> Pin-zu-Pin-Verdrahtung mit Drahtfarben.

![Schaltplan](img/hardware.png)

### Pin-Referenz (WireViz)

![WireViz Pin-Plan](img/wiring.png)

## Blockdiagramm (Mermaid-Übersicht)

ESP32 wird per **USB** versorgt (Power + Serial für External Mode), **12 V** vom Labornetzteil
gehen direkt auf **L298N VM**, gemeinsame Masse.

```mermaid
graph TB
    PC(["PC / Laptop"])
    PSU(["Labornetzteil 12V (strombegrenzt)"])

    subgraph ESP_GRP["ESP32-WROOM-32 DevKit"]
        ESP["ESP32<br/>LEDC PWM / Encoder-Interrupts"]
    end

    subgraph H_BRIDGE["L298N H-Bruecke (ENA-Jumper entfernt)"]
        ENA["ENA &larr; GPIO 14 (PWM)"]
        IN1["IN1 &larr; GPIO 26"]
        IN2["IN2 &larr; GPIO 27"]
        OUT["OUT1 / OUT2 ~8V"]
    end

    subgraph MOTOR_GROUP["Hyuduo 25GA371"]
        MOTOR["DC Motor 3000-8000 RPM"]
        ENC["Quadratur-Encoder A/B<br/>11 PPR, x4 = 44 CPR"]
    end

    subgraph FLYWHEEL["Schwungscheiben (nicht montiert — Trägheits-Demo nur in Simulation)"]
        FWS["S Ø60mm  J=1.5e-5 kgm²"]
        FWL["L Ø120mm J=3.6e-4 kgm²"]
    end

    PC  -->|"USB (Power + Serial / External Mode)"| ESP
    PSU -->|"12V"| H_BRIDGE

    ESP -->|"PWM"| ENA
    ESP -->|"HIGH/LOW"| IN1
    ESP -->|"HIGH/LOW"| IN2

    OUT -->|"Motor+ (rot) / Motor- (weiss)"| MOTOR

    ENC -->|"A &rarr; GPIO32 (gelb) / B &rarr; GPIO33 (gruen)"| ESP
    ESP -->|"3.3V (blau) / GND (schwarz)"| ENC

    MOTOR -->|"Welle"| FWS
    MOTOR -->|"Welle"| FWL

    PSU       -.->|"GND (gemeinsam)"| H_BRIDGE
    H_BRIDGE  -.->|"GND (gemeinsam)"| ESP

    style PSU   fill:#f5a623,stroke:#c47d0a,color:#000
    style ESP   fill:#2c6fad,stroke:#1a4a7a,color:#fff
    style ENA   fill:#7ed321,stroke:#5a9a18,color:#000
    style IN1   fill:#7ed321,stroke:#5a9a18,color:#000
    style IN2   fill:#7ed321,stroke:#5a9a18,color:#000
    style OUT   fill:#b8860b,stroke:#8b6508,color:#fff
    style MOTOR fill:#9b59b6,stroke:#6c3483,color:#fff
    style ENC   fill:#8e44ad,stroke:#6c3483,color:#fff
    style FWS   fill:#1abc9c,stroke:#16a085,color:#fff
    style FWL   fill:#16a085,stroke:#1a7a64,color:#fff
```

> ⚠️ Encoder mit **3.3V** versorgen — die ESP32-GPIOs sind **nicht** 5V-tolerant
> (VCC bestimmt den Pegel der A/B-Signale).

## Standalone-Versorgung (optional, ohne PC)

Für die finale Demo ohne Laptop kann der ESP32 alternativ versorgt werden:
- **USB-Powerbank** (einfachste Variante), **oder**
- **Power-Backpack mit 12 V direkt** (Barrel-Jack 6,5–16 V) → **kein Buck nötig**.

Ein **Buck-Converter** (12 V → 5 V → VIN) wird nur gebraucht, wenn weder Powerbank noch
Backpack genutzt werden. Im Prototyp-Aufbau ist er **nicht** verbaut.

## Pinbelegung Zusammenfassung

| Signal | ESP32 GPIO | Beschreibung |
|--------|-----------|-------------|
| PWM    | 14        | LEDC-PWM → L298N ENA |
| IN1    | 26        | Motorrichtung Bit 1 |
| IN2    | 27        | Motorrichtung Bit 2 |
| Enc A  | 32        | Interrupt (×4-Quadratur) — Motordraht **gelb** (siehe Hinweis) |
| Enc B  | 33        | Interrupt (×4-Quadratur) — Motordraht **grün** (siehe Hinweis) |
| Enc VCC| 3.3V      | Motordraht **blau** |
| Enc GND| GND       | Motordraht **schwarz** |

Pins folgen Raffls am Board getestetem Modell (`code_gen_ac2.slx`, 2026-07-06);
die früheren Draft-Pins 25/18/19 sind obsolet.

> ⚠️ **Offener Lab-Punkt Drahtfarben:** Die A/B-Farbzuordnung ist unbestätigt —
> `BOM.md` sagt A = grün, B = gelb (Datenblatt-Foto); dieses Diagramm sowie
> `schaltplan.drawio`/`draw_hardware.py` sagen A = gelb, B = grün. Im Lab per
> Drehrichtungs-Vorzeichen-Test verifizieren (TESTPLAN Stufe 2), nicht raten.

## Richtungslogik L298N

| IN1 | IN2 | Motor |
|-----|-----|-------|
| HIGH | LOW  | Vorwärts |
| LOW  | HIGH | Rückwärts |
| LOW  | LOW  | Freilauf |
| HIGH | HIGH | Bremse |

## Spannungshinweis

L298N hat ~4V Spannungsabfall → bei 12V Eingang kommen **~8V** am Motor an.

```
u(k) ∈ [−255, 255]  →  PWM duty [0..255] + IN1/IN2 für Vorzeichen
```
