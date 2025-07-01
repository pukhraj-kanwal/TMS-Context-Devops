# 15. DDD Deep Dive: The Asset Fleet Bounded Context

## 1. Overview

**Bounded Context:** Asset Fleet
**Microservice:** `asset-service` (NestJS)
**Core Responsibility:** To manage the lifecycle of a company's physical assets (trucks and trailers), including their specifications and maintenance history.

## 2. Ubiquitous Language (Expanded)

*   **Asset:** A physical piece of equipment used for transporting goods. The central Aggregate Root.
*   **Type:** The kind of asset (`TRUCK` or `TRAILER`).
*   **VIN (Vehicle Identification Number):** A unique identifier for an asset.
*   **Maintenance Log:** A record of a service performed on an asset. An Entity within the Asset Aggregate.
*   **Status:** The current state of the asset (`AVAILABLE`, `IN_USE`, `IN_MAINTENANCE`, `DECOMMISSIONED`).

## 3. The `Asset` Aggregate

### 3.1. Aggregate Root: `Asset`

*   **Properties (State):**
    *   `id` (UUID)
    *   `company_id` (UUID, Shard Key)
    *   `type` (String)
    *   `vin` (String)
    *   `make` (String)
    *   `model` (String)
    *   `year` (Integer)
    *   `status` (String)
    *   `maintenance_logs` (List of `MaintenanceLog` Entities)

### 3.2. Entity: `MaintenanceLog`

*   **Properties (State):**
    *   `id` (UUID)
    *   `service_date` (Date)
    *   `description` (String)
    *   `cost` (Decimal)

## 4. Invariants (Business Rules)

*   An `Asset`'s `vin` must be unique within a company.
*   An `Asset` that is `IN_MAINTENANCE` or `DECOMMISSIONED` cannot be assigned to a load.
*   An `Asset`'s status can only transition in a valid sequence.

## 5. Aggregate Methods (Behaviors/Commands)

*   `schedule_maintenance(description, service_date)`:
    *   Checks that the asset is not `DECOMMISSIONED`.
    *   Changes the `Asset`'s status to `IN_MAINTENANCE`.
    *   Creates a new `MaintenanceLog` entry.
    *   Publishes an `AssetMaintenanceScheduled` event.

*   `complete_maintenance()`:
    *   Checks that the asset is `IN_MAINTENANCE`.
    *   Changes the `Asset`'s status to `AVAILABLE`.
    *   Publishes an `AssetMaintenanceCompleted` event.

*   `decommission()`:
    *   Changes the `Asset`'s status to `DECOMMISSIONED`.
    *   Publishes an `AssetDecommissioned` event.

## 6. Domain Events

*   `AssetCreated`
*   `AssetMaintenanceScheduled`
*   `AssetMaintenanceCompleted`
*   `AssetDecommissioned`
