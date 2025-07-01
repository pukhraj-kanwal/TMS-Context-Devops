# 12. Roadmap: `notification-service` (NestJS)

**Agent Persona:** You are a NestJS specialist with experience in building event-driven systems. Your task is to build the `notification-service`, which is responsible for sending all user-facing communications.

## 1. Your Mission

To build a reliable and scalable service that consumes events from the TMS platform and sends notifications to users via multiple channels (initially email, with the ability to add SMS and push notifications later).

## 2. Core Requirements

*   **Technology Stack:** NestJS (TypeScript), Google Pub/Sub, Docker.
*   **Database:** This service is **stateless** and does not have its own database.
*   **API:** This service will not have a public-facing API. Its only entry points are the Pub/Sub subscriptions.
*   **Testing:** You must write tests to ensure that the service correctly consumes events and calls the appropriate third-party notification providers.
*   **Event Consumption:** You will subscribe to multiple Pub/Sub topics to receive events from other services.

## 3. Development Checklist

### Phase 1: Project Setup

- [ ] Initialize a new NestJS project in the `microservices/notification-service` directory.
- [ ] Create a `Dockerfile` for this service.

### Phase 2: Email Integration

- [ ] Choose and integrate a third-party email provider (e.g., SendGrid, Mailgun). Create a generic `EmailService` that abstracts the provider's API.
- [ ] Create email templates for the notifications you will be sending.

### Phase 3: Event Subscribers

- [ ] Create a `DispatchEventSubscriber` that listens for events from the `dispatch-service`.
    - [ ] **On `load.assigned` event:** Send an email to the assigned driver with the load details.
    - [ ] **On `stop.completed` event:** Send an email to the dispatcher with a status update.
- [ ] Create a `ComplianceEventSubscriber` that listens for events from the `compliance-service`.
    - [ ] **On `hos.violation` event:** Send an email to the compliance manager with the details of the violation.
- [ ] Create a `UserEventSubscriber` that listens for events from the `company-service`.
    - [ ] **On `user.created` event:** Send a welcome email to the new user.

### Phase 4: Testing

- [ ] For each event subscriber, write a unit test that ensures it correctly parses the event payload and calls the `EmailService` with the correct parameters.
- [ ] Use mocks to simulate the `EmailService` and the Pub/Sub client.

### Phase 5: Finalization

- [ ] Ensure all code is linted and formatted correctly.
- [ ] Ensure all tests are passing and code coverage meets the project standard (90%+).
- [ ] Create a Pull Request to the `develop` branch.
