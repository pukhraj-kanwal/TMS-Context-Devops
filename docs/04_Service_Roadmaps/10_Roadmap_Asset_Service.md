# 10. Roadmap: `asset-service` (NestJS)

**Agent Persona:** You are a NestJS specialist. Your task is to build the `asset-service`, which is responsible for managing a company's fleet of trucks and trailers.

## 1. Your Mission

To build a reliable API for managing all transportation assets. This service is the single source of truth for asset information, which is critical for dispatching and maintenance.

## 2. Core Requirements

*   **Technology Stack:** NestJS (TypeScript), PostgreSQL, Docker.
*   **Database Schema:** You will be working with the `asset_db` as defined in `03_Database_Architecture.md`. You are responsible for creating the initial migration script for this schema.
*   **API:** You will expose a RESTful API for all operations.
*   **Testing:** You must adhere to the TDD workflow. Every endpoint must have both unit and integration tests.

## 3. Development Checklist

### Phase 1: Project Setup

- [ ] Initialize a new NestJS project in the `microservices/asset-service` directory.
- [ ] Create a `Dockerfile` for this service.
- [ ] Create a `docker-compose.yml` file for local development, including a PostgreSQL container.

### Phase 2: Database and Migrations

- [ ] Create the initial Flyway migration script `V1.2.0__Create_asset_and_maintenance_log_tables.sql` in the `database/migrations` directory. This script should create the `ASSET` and `MAINTENANCE_LOG` tables as defined in `03_Database_Architecture.md`.
- [ ] Configure the NestJS application to use TypeORM to connect to the sharded `asset_db`.
- [ ] Create the TypeORM entities for `Asset` and `MaintenanceLog`.

### Phase 3: Asset Management

- [ ] Create an `AssetModule`.
- [ ] Implement an `AssetController` with the following endpoints:
    - [ ] `POST /assets`: Create a new asset (truck or trailer).
    - [ ] `GET /assets?companyId=:companyId`: Get a list of all assets for a company.
    - [ ] `GET /assets/:id?companyId=:companyId`: Get a single asset by ID.
    - [ ] `PUT /assets/:id`: Update an asset's information.
    - [ ] `DELETE /assets/:id`: Decommission an asset.
- [ ] Implement the `AssetService` with the business logic for asset CRUD operations.
- [ ] Write unit and integration tests for the asset endpoints.

### Phase 4: Maintenance Log Management

- [ ] Create a `MaintenanceModule`.
- [ ] Implement a `MaintenanceController` with the following endpoints:
    - [ ] `POST /assets/:assetId/maintenance-logs`: Create a new maintenance log for an asset.
    - [ ] `GET /assets/:assetId/maintenance-logs`: Get a list of maintenance logs for an asset.
- [ ] Implement the `MaintenanceService`.
- [ ] Write unit and integration tests.

### Phase 5: Finalization

- [ ] Ensure all code is linted and formatted correctly.
- [ ] Ensure all tests are passing and code coverage meets the project standard (90%+).
- [ ] Create a Pull Request to the `develop` branch.
