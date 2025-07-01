# 08. Roadmap: `company-service` (NestJS)

**Agent Persona:** You are a NestJS specialist. Your task is to build the `company-service`, which is the foundation of the entire TMS. This service manages tenants (companies), users, and their roles.

## 1. Your Mission

To build a robust, well-tested, and secure API for managing companies, users, and roles. This service is the single source of truth for identity and access control.

## 2. Core Requirements

*   **Technology Stack:** NestJS (TypeScript), PostgreSQL, Docker.
*   **Database Schema:** You will be working with the `company_db` as defined in `03_Database_Architecture.md`. You are responsible for creating the initial migration script for this schema.
*   **API:** You will expose a RESTful API for all operations.
*   **Testing:** You must adhere to the TDD workflow. Every endpoint must have both unit and integration tests.
*   **Events:** You will publish events to Google Pub/Sub when a company or user is created.

## 3. Development Checklist

### Phase 1: Project Setup

- [ ] Initialize a new NestJS project in the `microservices/company-service` directory.
- [ ] Create a `Dockerfile` for this service.
- [ ] Create a `docker-compose.yml` file for local development, including a PostgreSQL container.

### Phase 2: Database and Migrations

- [ ] Create the initial Flyway migration script `V1.0.0__Create_company_user_role_tables.sql` in the `database/migrations` directory. This script should create the `COMPANY`, `USER`, `ROLE`, and `USER_ROLE` tables as defined in `03_Database_Architecture.md`.
- [ ] Configure the NestJS application to use TypeORM to connect to the PostgreSQL database.
- [ ] Create the TypeORM entities for `Company`, `User`, and `Role`.

### Phase 3: Company Management

- [ ] Create a `CompanyModule`.
- [ ] Implement the `CompanyController` with the following endpoints:
    - [ ] `POST /companies`: Create a new company.
    - [ ] `GET /companies`: Get a list of all companies.
    - [ ] `GET /companies/:id`: Get a single company by ID.
- [ ] Implement the `CompanyService` with the business logic for creating and retrieving companies.
- [ ] Write unit tests for the `CompanyService`.
- [ ] Write integration tests for the `CompanyController` endpoints.

### Phase 4: User Management

- [ ] Create a `UserModule`.
- [ ] Implement the `UserController` with the following endpoints:
    - [ ] `POST /users`: Create a new user for a specific company.
    - [ ] `GET /users?companyId=:companyId`: Get a list of users for a company.
- [ ] Implement the `UserService`.
- [ ] Implement password hashing using `bcrypt`.
- [ ] Write unit and integration tests.

### Phase 5: Event Publishing

- [ ] Integrate the Google Cloud Pub/Sub client library.
- [ ] When a new company is created, publish a `company.created` event to the `company-events` topic. The event payload should be a JSON object with the company's ID and name.
- [ ] When a new user is created, publish a `user.created` event. The payload should include the user's ID, email, and `company_id`.
- [ ] Write tests to ensure that events are published correctly.

### Phase 6: Finalization

- [ ] Ensure all code is linted and formatted correctly.
- [ ] Ensure all tests are passing and code coverage meets the project standard (90%+).
- [ ] Create a Pull Request to the `develop` branch.
