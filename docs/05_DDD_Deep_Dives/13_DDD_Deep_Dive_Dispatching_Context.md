# 13. DDD Deep Dive: The Dispatching Bounded Context

## 1. Overview

**Bounded Context:** Dispatching
**Microservice:** `dispatch-service` (FastAPI)
**Core Responsibility:** To manage the lifecycle of a load, from creation to completion, including the assignment of drivers and assets.

## 2. Ubiquitous Language (Expanded)

*   **Load:** A shipment of goods. The central Aggregate Root of this context.
*   **Stop:** A location where a pickup or dropoff occurs. An Entity within the Load Aggregate.
*   **Route:** The planned sequence of stops for a load. A Value Object.
*   **Assignment:** The act of linking a `Driver`, `Truck`, and `Trailer` to a `Load`. This is a key business operation.
*   **Status:** The current state of the load (`PENDING`, `ASSIGNED`, `IN_TRANSIT`, `COMPLETED`, `CANCELLED`).

## 3. The `Load` Aggregate

### 3.1. Aggregate Root: `Load`

*   **Properties (State):**
    *   `id` (UUID)
    *   `company_id` (UUID, Shard Key)
    *   `status` (String)
    *   `assigned_driver_id` (UUID, nullable)
    *   `primary_truck_id` (UUID, nullable)
    *   `primary_trailer_id` (UUID, nullable)
    *   `stops` (List of `Stop` Entities)

### 3.2. Entity: `Stop`

*   **Properties (State):**
    *   `id` (UUID)
    *   `stop_number` (Integer)
    *   `type` (String: `PICKUP`, `DROPOFF`)
    *   `address` (Value Object)
    *   `scheduled_time` (DateTime)
    *   `actual_arrival_time` (DateTime, nullable)
    *   `is_completed` (Boolean)

### 3.3. Value Object: `Address`

*   **Properties (State):**
    *   `street` (String)
    *   `city` (String)
    *   `state` (String)
    *   `zip_code` (String)

## 4. Invariants (Business Rules)

These are the rules that the `Load` Aggregate must enforce at all times. Any operation that would violate an invariant must be rejected.

*   A `Load` must have at least two `Stops`: one `PICKUP` and one `DROPOFF`.
*   A `Load` cannot be `ASSIGNED` if it does not have a valid route (i.e., a sequence of stops).
*   A `Driver` can only be assigned to a `Load` if their status is `available` (this data comes from the `driver-service`).
*   A `Load`'s status can only transition in a valid sequence (e.g., `PENDING` -> `ASSIGNED`, not `COMPLETED` -> `IN_TRANSIT`).
*   A `Stop` cannot be marked as `completed` out of order.
*   A `Load` cannot be assigned if it is `CANCELLED` or `COMPLETED`.

## 5. Aggregate Methods (Behaviors/Commands)

*   `assign_driver(driver_id, truck_id, trailer_id)`:
    *   Checks the `Load`'s status invariant.
    *   (Communicates with other services to check driver/asset availability - this is a domain service responsibility).
    *   If successful, updates the `assigned_driver_id`, `primary_truck_id`, and `primary_trailer_id`.
    *   Changes the `Load`'s status to `ASSIGNED`.
    *   Publishes a `LoadAssigned` domain event.

*   `start_transit()`:
    *   Checks that the `Load` is in the `ASSIGNED` state.
    *   Changes the `Load`'s status to `IN_TRANSIT`.
    *   Publishes a `LoadInTransit` domain event.

*   `complete_stop(stop_id)`:
    *   Checks the `Load`'s status and the stop order invariants.
    *   Marks the specified `Stop` as `completed`.
    *   If this is the final stop, changes the `Load`'s status to `COMPLETED` and publishes a `LoadCompleted` event.
    *   Otherwise, publishes a `StopCompleted` event.

*   `cancel_load(reason)`:
    *   Checks that the `Load` is not already `COMPLETED`.
    *   Changes the `Load`'s status to `CANCELLED`.
    *   Publishes a `LoadCancelled` domain event.

## 6. Domain Events

These events are published by the `Load` Aggregate when its state changes. They are used for asynchronous communication with other Bounded Contexts (like the `notification-service`).

*   `LoadCreated`
*   `LoadAssigned`
*   `LoadInTransit`
*   `StopCompleted`
*   `LoadCompleted`
*   `LoadCancelled`
