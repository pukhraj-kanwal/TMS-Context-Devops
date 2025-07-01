# 09. Roadmap: `driver-service` (NestJS)

**Agent Persona:** You are a NestJS specialist. Your task is to build the `driver-service`, which manages driver profiles and their Hours of Service (HOS) logs. This service is critical for compliance and dispatching.

## 1. Your Mission

To build a robust and scalable API for managing drivers and their HOS logs. This service will consume events from the `company-service` to automatically create driver profiles.

## 2. Core Requirements

*   **Technology Stack:** NestJS (TypeScript), PostgreSQL, Docker.
*   **Database Schema:** You will be working with the `driver_db` as defined in `03_Database_Architecture.md`. You are responsible for creating the initial migration script for this schema.
*   **API:** You will expose a RESTful API for all operations.
*   **Testing:** You must adhere to the TDD workflow. Every endpoint must have both unit and integration tests.
*   **Event Consumption:** You will subscribe to Google Pub/Sub to receive `user.created` events.

## 3. Development Checklist

### Phase 1: Project Setup

- [ ] Initialize a new NestJS project in the `microservices/driver-service` directory.
- [ ] Create a `Dockerfile` for this service.
- [ ] Create a `docker-compose.yml` file for local development, including a PostgreSQL container.

### Phase 2: Database and Migrations

- [ ] Create the initial Flyway migration script `V1.1.0__Create_driver_and_hos_log_tables.sql` in the `database/migrations` directory. This script should create the `DRIVER` and `HOS_LOG` tables as defined in `03_Database_Architecture.md`.
- [ ] Configure the NestJS application to use TypeORM to connect to the sharded `driver_db`. The application will need a mechanism to determine the correct shard based on the `company_id`.
- [ ] Create the TypeORM entities for `Driver` and `HosLog`.

### Phase 3: Event-Driven Driver Creation

- [ ] Create a `UserEventSubscriber` that listens for `user.created` events on the `user-events` Pub/Sub topic.
- [ ] When a `user.created` event is received, the subscriber should check if the user has the `driver` role.
- [ ] If the user is a driver, the service should automatically create a new `Driver` profile associated with the user's `company_id`.
- [ ] Write tests to ensure that drivers are created correctly from events.

### Phase 4: Driver Profile Management

- [ ] Create a `DriverModule`.
- [ ] Implement a `DriverController` with the following endpoints:
    - [ ] `GET /drivers?companyId=:companyId`: Get a list of all drivers for a company.
    - [ ] `GET /drivers/:id?companyId=:companyId`: Get a single driver by ID.
    - [ ] `PUT /drivers/:id`: Update a driver's profile (e.g., license number).
- [ ] Implement the `DriverService` with the business logic for retrieving and updating drivers.
- [ ] Write unit and integration tests for the driver profile endpoints.

### Phase 5: HOS Log Management

- [ ] Create an `HosModule`.
- [ ] Implement an `HosController` with the following endpoints:
    - [ ] `POST /drivers/:driverId/hos-logs`: Create a new HOS log for a driver.
    - [ ] `GET /drivers/:driverId/hos-logs`: Get a list of HOS logs for a driver.
- [ ] Implement the `HosService`.
- [ ] Write unit and integration tests.

### Phase 6: Finalization

- [ ] Ensure all code is linted and formatted correctly.
- [ ] Ensure all tests are passing and code coverage meets the project standard (90%+).
- [ ] Create a Pull Request to the `develop` branch.
