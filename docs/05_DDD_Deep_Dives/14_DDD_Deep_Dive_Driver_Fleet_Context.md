# 14. DDD Deep Dive: The Driver Fleet Bounded Context

## 1. Overview

**Bounded Context:** Driver Fleet
**Microservice:** `driver-service` (NestJS)
**Core Responsibility:** To manage the profiles of drivers and their compliance with Hours of Service (HOS) regulations.

## 2. Ubiquitous Language (Expanded)

*   **Driver:** An individual who operates a commercial motor vehicle. The central Aggregate Root.
*   **HOS (Hours of Service):** The set of rules governing the working hours of a driver.
*   **Log:** A record of a driver's HOS status. An Entity within the Driver Aggregate.
*   **Status:** The current HOS status of a driver (`ON_DUTY`, `OFF_DUTY`, `SLEEPER_BERTH`, `DRIVING`).
*   **Shift:** A continuous period of `ON_DUTY` and `DRIVING` time.
*   **Cycle:** The total `ON_DUTY` time accumulated over a defined period (e.g., 70 hours in 8 days).

## 3. The `Driver` Aggregate

### 3.1. Aggregate Root: `Driver`

*   **Properties (State):**
    *   `id` (UUID)
    *   `company_id` (UUID, Shard Key)
    *   `first_name` (String)
    *   `last_name` (String)
    *   `license_number` (String)
    *   `current_status` (String)
    *   `hos_logs` (List of `HosLog` Entities)

### 3.2. Entity: `HosLog`

*   **Properties (State):**
    *   `id` (UUID)
    *   `status` (String)
    *   `start_time` (DateTime)
    *   `end_time` (DateTime, nullable)
    *   `location` (Value Object)

## 4. Invariants (Business Rules)

*   A `Driver` cannot have overlapping `HosLog` entries.
*   A `Driver`'s status can only transition in a valid sequence (e.g., `OFF_DUTY` -> `ON_DUTY`).
*   A `Driver` cannot exceed the maximum `DRIVING` time allowed in a shift.
*   A `Driver` cannot exceed the maximum `ON_DUTY` time allowed in a cycle.
*   A `Driver` must take a minimum rest period between shifts.

## 5. Aggregate Methods (Behaviors/Commands)

*   `change_status(new_status, location)`:
    *   Checks the HOS invariants (e.g., have they been off-duty long enough?).
    *   Ends the current `HosLog` by setting its `end_time`.
    *   Creates a new `HosLog` with the `new_status` and the current time as `start_time`.
    *   Updates the `Driver`'s `current_status`.
    *   If the `new_status` change results in a violation, it publishes a `HosViolationDetected` event.
    *   Publishes a `DriverStatusChanged` event.

*   `update_profile(first_name, last_name, license_number)`:
    *   Updates the driver's personal information.
    *   Publishes a `DriverProfileUpdated` event.

## 6. Domain Events

*   `DriverCreated` (from user event)
*   `DriverStatusChanged`
*   `DriverProfileUpdated`
*   `HosViolationDetected`
