# Bill of Materials - Adaptive Control DC Motor Test Bench

**Project:** Adaptive Control of a DC Motor (Example 7.6)

## Electronics

| # | Component | Product | Compatibility | Approx. price |
|---|---|---|---|---:|
| E1 | DC motor with encoder | Hyuduo 25GA371, 12 V, integrated quadrature encoder | 12 V motor, encoder operated at 3.3 V with ESP32 GPIOs | EUR 14 |
| E2 | ESP32 DevKit | ESP32-WROOM-32 DevKit | LEDC PWM and interrupt-capable encoder pins | EUR 7-10 |
| E3 | Motor driver | DollaTek L298N Mini Dual H-Bridge (B07DK6Q8F9) | 5-35 V motor supply, 3.3 V logic drive from ESP32 is sufficient | EUR 5 |
| E4 | Step-down converter | APKLVSR DC-DC buck, 4-40 V to 1.25-37 V, 3 A, display (B0D8SRX3NY) | Optional for stand-alone operation; not fitted in the prototype | EUR 8 |
| E5 | Barrel jack socket | RUNCCI-YUN 5.5/2.1 mm socket (B0CH7WX85X) | Standard DC supply connector | EUR 3 |
| E6 | Bench supply | Current-limited 12 V bench supply | 12 V directly to L298N VM, common ground | - |
| E7 | Jumper wire set | M-F and M-M, 20 cm | Prototype wiring | EUR 3 |

The AS5600 encoder is not used because the 25GA371 already includes a quadrature encoder with A and B outputs connected directly to ESP32 interrupt pins.

The gearbox has been removed from the 25GA371. The motor therefore runs as a gearbox-free DC motor at roughly 3000-8000 rpm rather than the geared product-page speed. RLS estimates the effective output parameters `a0` and `b0`, so the controller adapts to the resulting plant.

The L298N drops about 4 V. With a 12 V supply, the motor terminals therefore see about 8 V. The optional step-down converter is only needed for alternative stand-alone supply arrangements.

## Wiring Overview

```text
Current-limited 12 V bench supply
    |
    +-- optional stand-alone path: barrel jack (E5) -> step-down (E4) -> 5 V
    |
    +-- L298N VM
    |   L298N GND
    |   L298N ENA -> ESP32 GPIO 14 (PWM)
    |   L298N IN1 -> ESP32 GPIO 26 (direction)
    |   L298N IN2 -> ESP32 GPIO 27 (direction)
    |   L298N OUT1/OUT2 -> 25GA371 motor leads
    |
    +-- ESP32 powered by USB or power shield
            |
            +-- GPIO 32 -> Encoder channel A
            +-- GPIO 33 -> Encoder channel B
            +-- 3.3 V   -> Encoder VCC
            +-- GND     -> Encoder GND
```

## 25GA371 Connections

| Lead | Function | Connects to |
|---|---|---|
| Red | Motor + | L298N OUT1 |
| White | Motor - | L298N OUT2 |
| Blue | Encoder VCC | ESP32 **3.3 V** |
| Black | Encoder GND | ESP32 GND |
| Encoder A | Quadrature channel A | ESP32 GPIO 32 |
| Encoder B | Quadrature channel B | ESP32 GPIO 33 |

Do not swap blue and black. The encoder is powered from **3.3 V only** because the ESP32 GPIOs are not 5 V tolerant.

Encoder resolution is measured as **44 counts per motor revolution**: 11 impulses with x4 quadrature edge decoding.

## Mechanics - Acrylic Parts

| # | Part | Dimensions | Thickness | Mass | J |
|---|---|---:|---:|---:|---:|
| P1 | Base plate | 200 x 150 mm | 12 mm | - | - |
| P2 | Flywheel S | diameter 60 mm | 10 mm | 33.6 g | 1.5e-5 kg m^2 |
| P3 | Flywheel L | diameter 120 mm | 15 mm | 201.9 g | 3.6e-4 kg m^2 |

The S-to-L inertia ratio is about 24:1, which gives a clear dynamics change for the adaptive-control demonstration. The flywheels are designed but not mounted for the submission; the physical test bench uses the bare motor, and the S->L->S inertia-change scenario is demonstrated in simulation.

## Mechanics - 3D-Printed Parts

| # | Part | Function | Note |
|---|---|---|---|
| D1 | Motor bracket | Mounts the 25GA371 on the base plate | Match the motor housing |
| D2 | Hub adaptor S | Connects the output shaft to the 60 mm flywheel | Match the 25GA371 shaft diameter before fabrication |
| D3 | Hub adaptor L | Connects the output shaft to the 120 mm flywheel | Match the 25GA371 shaft diameter before fabrication |
| D4 | ESP32 bracket | Holds the ESP32 DevKit on the base plate | Match the board version |
| D5 | L298N bracket | Holds the motor driver on the base plate | 43 x 43 mm footprint |
| D6 | Step-down bracket | Holds the step-down module on the base plate | 61 x 34 mm footprint |

## Fasteners

| # | Part | Quantity |
|---|---|---:|
| B1 | M3 screws, 6/8/10/12 mm | 5 each |
| B2 | M3 nuts | 20 |
| B3 | M3 heat-set inserts | 15 |
| B4 | M3 washers | 10 |
| B5 | M2 grub screws | 4 |

## Cost Summary

| Category | Approx. cost |
|---|---:|
| Electronics already selected | EUR 30 |
| ESP32, supply and wiring allowance | EUR 18-25 |
| Acrylic from stock | EUR 0-10 |
| 3D-printing filament, about 60 g | EUR 1-2 |
| Fasteners | EUR 3-5 |
| **Total** | **EUR 52-72** |
