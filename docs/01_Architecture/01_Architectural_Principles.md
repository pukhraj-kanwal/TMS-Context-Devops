# 01. Architectural Principles

## 1. The Prime Directive: Evolvability

The single most important quality of our architecture is **evolvability**. The logistics industry is constantly changing, and our system must be able to adapt without requiring a complete rewrite. Every architectural decision documented here is made with the goal of creating a system that is easy to change, extend, and maintain.

## 2. Our Core Architectural Tenets

1.  **Domain-Driven Design (DDD) is Law:** We model the business domain. Our code is a direct reflection of the business processes. Bounded Contexts define our service boundaries. The Ubiquitous Language is used in all communication.

2.  **Services are Autonomous:** Each microservice is a self-contained unit with its own database and its own release cycle. A change to one service should not require a change to another.

3.  **Communication is Asynchronous:** We favor asynchronous, event-based communication (via Google Pub/Sub) over synchronous, request/response communication. This decouples our services and makes the system more resilient to failure.

4.  **The API is the Contract:** All inter-service communication happens through well-defined, versioned APIs. There is no direct database-to-database communication between services.

5.  **Data is Sharded, Security is Absolute:** We use a multi-tenant, sharded database architecture to ensure complete data isolation between our customers. Security is not an afterthought; it is built into the foundation of the system.

6.  **Infrastructure is Code (IaC):** Our entire cloud environment is defined as code using Terraform. This ensures that our infrastructure is repeatable, auditable, and easy to change.

7.  **CI/CD is the Gatekeeper:** The CI/CD pipeline is the only way to deploy code to any environment. There are no manual deployments.

## 3. The Hybrid Microservices Strategy

We are not dogmatic about using a single technology. We use the best tool for the job.

*   **NestJS (Node.js/TypeScript):** Used for our standard, I/O-bound business logic services (`company-service`, `driver-service`, `asset-service`). NestJS provides a robust, opinionated framework that helps us build maintainable and testable APIs.

*   **FastAPI (Python):** Used for our data-intensive and AI/ML services (`dispatch-service`, `compliance-service`, `ai-agent-service`). Python's rich ecosystem of data science libraries makes it the ideal choice for these tasks.

## 4. The Trade-Offs We've Made

*   **Complexity vs. Scalability:** A microservices architecture is more complex than a monolith, but it provides the scalability and evolvability we need to achieve our long-term vision.
*   **Consistency vs. Availability:** By favoring asynchronous communication, we are choosing eventual consistency over strong consistency in many parts of our system. This makes the system more available and resilient, but it requires careful design to handle data that may not be immediately consistent.
*   **Cost vs. Managed Services:** We are choosing to use managed services (GKE, Cloud SQL, Apigee) wherever possible. This increases our operational costs, but it significantly reduces our operational overhead and allows us to focus on building our product.
