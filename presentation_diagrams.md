# Präsentation – Diagramme & Inhalte
## Adaptive Control of a DC Motor (Example 7.6)

> **Workflow für PowerPoint**: Mermaid-Code auf https://mermaid.live einfügen
> → rechts oben "PNG" oder "SVG" herunterladen → in Folie einfügen

---

## Diagramm 1 – Hardware-Aufbau

```mermaid
graph TB
    PSU(["⚡ 12V Netzteil\n≥ 2A"])
    TB[/"🔲 Klemmenblock"/]

    subgraph BUCK["Step-Down Converter"]
        BC["12V → 5V\nAPKLVSR Buck"]
    end

    subgraph MCU["Mikrocontroller"]
        ESP["ESP32\nLEDC PWM + Interrupts"]
    end

    subgraph DRIVER["Motortreiber"]
        L298N["L298N H-Brücke\n~4V Spannungsabfall"]
    end

    subgraph PLANT["DC Motor  —  Hyuduo 25GA371"]
        MOT["Motor\n(Getriebe entfernt)"]
        ENC["Quadratur-Encoder\nA / B"]
    end

    subgraph FW["Schwungscheibe (Plexiglas)"]
        FWS["Klein  Ø60mm\nJ = 1.5×10⁻⁵ kgm²"]
        FWL["Groß  Ø120mm\nJ = 3.6×10⁻⁴ kgm²"]
    end

    PSU -->|"12V"| TB
    TB  -->|"12V"| BC
    TB  -->|"12V"| L298N
    BC  -->|"5V"| ESP

    ESP -->|"GPIO 14  PWM"| L298N
    ESP -->|"GPIO 26/27  Richtung"| L298N
    L298N -->|"~8V"| MOT

    ENC -->|"GPIO 32  Kanal A\nGPIO 33  Kanal B"| ESP
    ESP -->|"3.3V / GND"| ENC

    MOT --- FWS
    MOT --- FWL

    style PSU   fill:#f39c12,stroke:#e67e22,color:#000
    style TB    fill:#c0392b,stroke:#922b21,color:#fff
    style BC    fill:#e67e22,stroke:#ca6f1e,color:#fff
    style ESP   fill:#2980b9,stroke:#1a5276,color:#fff
    style L298N fill:#27ae60,stroke:#1e8449,color:#fff
    style MOT   fill:#8e44ad,stroke:#6c3483,color:#fff
    style ENC   fill:#7d3c98,stroke:#5b2c6f,color:#fff
    style FWS   fill:#16a085,stroke:#0e6655,color:#fff
    style FWL   fill:#0e6655,stroke:#0a4f41,color:#fff
```

---

## Diagramm 2 – Adaptiver Regelkreis (Algorithmus)

```mermaid
graph LR
    REF(["ω_ref\nSollwert"])

    subgraph CTRL["Adaptiver Regler  —  läuft auf ESP32  T = 0.08 s"]
        direction TB
        ERR["e(k) = ω_ref − ω(k)"]
        PI["PI-Regler\nu(k) = u(k−1) + d₁·e(k) + d₀·e(k−1)"]
        PP["Pol-Platzierung\nd₀ = (q₀ + â₀) / b̂₀\nd₁ = (q₁ + 1 − â₀) / b̂₀"]
        RLS["RLS-Schätzer\nschätzt â₀, b̂₀\nonline"]

        ERR --> PI
        PP --> PI
        RLS --> PP
    end

    subgraph PLANT["Regelstrecke"]
        PWM["L298N\nH-Brücke"]
        MOT["DC Motor\n25GA371"]
        ENC["Encoder\n→ ω(k) messen"]
        PWM --> MOT --> ENC
    end

    REF --> ERR
    PI -->|"u(k)\nPWM Duty"| PWM
    ENC -->|"ω(k)"| ERR
    ENC -->|"y(k), u(k−1)"| RLS

    style REF  fill:#f39c12,stroke:#e67e22,color:#000
    style ERR  fill:#2980b9,stroke:#1a5276,color:#fff
    style PI   fill:#2471a3,stroke:#1a5276,color:#fff
    style PP   fill:#1a5276,stroke:#154360,color:#fff
    style RLS  fill:#117a65,stroke:#0e6655,color:#fff
    style PWM  fill:#27ae60,stroke:#1e8449,color:#fff
    style MOT  fill:#8e44ad,stroke:#6c3483,color:#fff
    style ENC  fill:#7d3c98,stroke:#5b2c6f,color:#fff
```

---

## Komponentenliste

| # | Komponente | Modell | Funktion | Schlüsselparameter |
|---|---|---|---|---|
| E1 | DC Motor + Encoder | Hyuduo 25GA371 | Regelstrecke + Drehzahlmessung | 12V, Quadratur-Encoder, Getriebe entfernt |
| E2 | Mikrocontroller | ESP32 DevKit | Regler, RLS, PWM-Ausgabe | 240 MHz, LEDC PWM, 2× Interrupt-GPIO |
| E3 | Motortreiber | L298N H-Brücke | Motoransteuerung bidirektional | 5–35V, 2A, ~4V Spannungsabfall |
| E4 | Step-Down Converter | APKLVSR Buck | 12V → 5V für ESP32 | 4–40V Eingang, 3A |
| E5 | Klemmenblock | — | Spannungsverteilung 12V | — |
| P1 | Schwungscheibe S | Plexiglas Ø60×10mm | Kleines Massenträgheitsmoment | J = 1.5×10⁻⁵ kgm² |
| P2 | Schwungscheibe L | Plexiglas Ø120×15mm | Großes Massenträgheitsmoment | J = 3.6×10⁻⁴ kgm² |
| P3 | Grundplatte | Plexiglas 200×150×12mm | Träger für alle Komponenten | — |

**Demo-Kern**: Durch Wechsel von Schwungscheibe S → L ändert sich J um Faktor **24** → RLS erkennt die Parameteränderung und der Regler passt sich automatisch an — ohne manuellen Eingriff.

---

## Foliengliederung (Vorschlag)

1. **Titel** – Adaptive Control of a DC Motor
2. **Aufgabenstellung** – Warum adaptiv? Problem der unbekannten / sich ändernden Parameter
3. **Systemmodell** – G(s) = Km/J / (s + b/J) → diskretisiert → a₀, b₀
4. **Algorithmus** – Diagramm 2 (Regelkreis)
5. **Hardware** – Diagramm 1 + Komponentenliste
6. **Demo-Plan** – Schwungscheibe S → Regler läuft → Scheibe wechseln → Adaptation beobachten
7. **Zeitplan / Status** – Was fertig, was noch offen (H-Brücke ausstehend)
