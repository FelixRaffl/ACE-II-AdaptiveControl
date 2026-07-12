# Hardware Diagram - Adaptive Control DC Motor

The rendered schematic is [`img/hardware.png`](img/hardware.png), generated from [`draw_hardware.py`](draw_hardware.py). The editable Draw.io source is [`schaltplan.drawio`](schaltplan.drawio). The pin-to-pin reference is generated from [`wiring.yml`](wiring.yml) as [`img/wiring.png`](img/wiring.png).

![Hardware schematic](img/hardware.png)

## Pin Reference

![WireViz pin plan](img/wiring.png)

## Block Diagram

The ESP32 is supplied through USB for power and External Mode communication. The current-limited 12 V bench supply feeds the L298N VM input directly, and all modules share a common ground.

```mermaid
graph TB
    PC(["PC / Laptop"])
    PSU(["12 V bench supply<br/>current limited"])

    subgraph ESP_GRP["ESP32-WROOM-32 DevKit"]
        ESP["ESP32<br/>LEDC PWM / encoder interrupts"]
    end

    subgraph H_BRIDGE["L298N H-bridge<br/>ENA jumper removed"]
        ENA["ENA <- GPIO 14 (PWM)"]
        IN1["IN1 <- GPIO 26"]
        IN2["IN2 <- GPIO 27"]
        OUT["OUT1 / OUT2 about 8 V"]
    end

    subgraph MOTOR_GROUP["Hyuduo 25GA371"]
        MOTOR["DC motor 3000-8000 rpm"]
        ENC["Quadrature encoder A/B<br/>11 PPR, x4 = 44 CPR"]
    end

    subgraph FLYWHEEL["Flywheels<br/>not mounted; inertia change is simulation only"]
        FWS["S diameter 60 mm, J=1.5e-5 kg m^2"]
        FWL["L diameter 120 mm, J=3.6e-4 kg m^2"]
    end

    PC  -->|"USB (power + serial / External Mode)"| ESP
    PSU -->|"12 V"| H_BRIDGE

    ESP -->|"PWM"| ENA
    ESP -->|"HIGH/LOW"| IN1
    ESP -->|"HIGH/LOW"| IN2

    OUT -->|"Motor+ / Motor-"| MOTOR

    ENC -->|"A -> GPIO32 / B -> GPIO33"| ESP
    ESP -->|"3.3 V / GND"| ENC

    MOTOR -->|"Shaft"| FWS
    MOTOR -->|"Shaft"| FWL

    PSU       -.->|"Common GND"| H_BRIDGE
    H_BRIDGE  -.->|"Common GND"| ESP

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

Power the encoder from **3.3 V only**. The ESP32 GPIOs are not 5 V tolerant.

## Optional Stand-Alone Supply

For operation without a laptop, the ESP32 can be supplied either from a USB power bank or from the power shield with 12 V at its barrel jack. A separate buck converter is only needed when neither of these options is used; it is not fitted in the prototype.

## Pin Assignment

| Signal | ESP32 GPIO | Description |
|---|---:|---|
| PWM | 14 | LEDC PWM to L298N ENA |
| IN1 | 26 | Motor direction bit 1 |
| IN2 | 27 | Motor direction bit 2 |
| Encoder A | 32 | Interrupt input, x4 quadrature |
| Encoder B | 33 | Interrupt input, x4 quadrature |
| Encoder VCC | 3.3 V | Encoder supply |
| Encoder GND | GND | Encoder ground |

The active pin assignment is GPIO 14/26/27/32/33. Earlier draft pins 25/18/19 are obsolete.

## L298N Direction Logic

| IN1 | IN2 | Motor state |
|---|---|---|
| HIGH | LOW | Forward |
| LOW | HIGH | Reverse |
| LOW | LOW | Coast |
| HIGH | HIGH | Brake |

## Voltage Note

The L298N drops about 4 V, so a 12 V input gives about 8 V at the motor terminals.

```text
u(k) in [-255, 255] -> PWM duty [0..255] plus IN1/IN2 sign mapping
```
