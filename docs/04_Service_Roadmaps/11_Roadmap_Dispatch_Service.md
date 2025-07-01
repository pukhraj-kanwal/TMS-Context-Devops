# 11. Roadmap: `dispatch-service` (FastAPI)

**Agent Persona:** You are a Python and FastAPI specialist. Your task is to build the `dispatch-service`, which is the core of the TMS. This service manages loads, stops, and the complex logic of assigning loads to drivers and assets.

## 1. Your Mission

To build a high-performance API for managing all aspects of the dispatching process. This service will be the central hub for a company's daily operations.

## 2. Core Requirements

*   **Technology Stack:** Python 3.10+, FastAPI, Pydantic, SQLAlchemy, PostgreSQL, Docker.
*   **Database Schema:** You will be working with the `dispatch_db` as defined in `03_Database_Architecture.md`. You are responsible for creating the initial migration script for this schema.
*   **API:** You will expose a RESTful API for all operations.
*   **Testing:** You must adhere to the TDD workflow using `pytest`. Every endpoint must have both unit and integration tests.

## 3. Development Checklist

### Phase 1: Project Setup

- [ ] Initialize a new FastAPI project in the `microservices/dispatch-service` directory.
- [ ] Structure the project with a clear separation of concerns (e.g., `api`, `services`, `models`, `repositories`).
- [ ] Create a `Dockerfile` for this service.
- [ ] Create a `docker-compose.yml` file for local development, including a PostgreSQL container.

### Phase 2: Database and Migrations

- [ ] Create the initial Flyway migration script `V1.3.0__Create_load_and_stop_tables.sql` in the `database/migrations` directory. This script should create the `LOAD` and `STOP` tables as defined in `03_Database_Architecture.md`.
- [ ] Configure the FastAPI application to use SQLAlchemy to connect to the sharded `dispatch_db`.
- [ ] Create the SQLAlchemy models for `Load` and `Stop`.

### Phase 3: Load Management

- [ ] Create a `LoadAPI` router.
- [ ] Implement the following endpoints:
    - [ ] `POST /loads`: Create a new load.
    - [ ] `GET /loads?companyId=:companyId`: Get a list of all loads for a company.
    - [ ] `GET /loads/:id?companyId=:companyId`: Get a single load by ID.
    - [ ] `PUT /loads/:id/assign`: Assign a driver and assets to a load.
- [ ] Implement the `LoadService` with the business logic for load management.
- [ ] Write unit tests for the `LoadService`.
- [ ] Write integration tests for the `LoadAPI` endpoints using `pytest` and `TestClient`.

### Phase 4: Stop Management

- [ ] Create a `StopAPI` router.
- [ ] Implement the following endpoints:
    - [ ] `POST /loads/:loadId/stops`: Add a new stop to a load.
    - [ ] `GET /loads/:loadId/stops`: Get all stops for a load.
    - [ ] `PUT /stops/:id/complete`: Mark a stop as completed.
- [ ] Implement the `StopService`.
- [ ] Write unit and integration tests.

### Phase 5: Finalization

- [ ] Ensure all code is linted with `black` and `flake8` and type-checked with `mypy`.
- [ ] Ensure all tests are passing and code coverage meets the project standard (90%+).
- [ ] Create a Pull Request to the `develop` branch.
