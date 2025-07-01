# 05. The Development Workflow

## 1. The Philosophy: The "Card Rails" of Quality

This is the mandatory, step-by-step workflow for all code contributions. It is designed to ensure that every change is small, verifiable, and of the highest quality. We call this system the "Card Rails" because it guides the developer from the start of a task to its successful completion.

## 2. The Git Workflow: A Strict Branching Model

We use a modified GitFlow model. See `06_Git_and_CI_CD_Workflow.md` for the full details. The key points are:

*   `main` is always production-ready.
*   `develop` is the integration branch for the next release.
*   All new work is done on `feature/` branches.

## 3. The TDD Cycle: Red, Green, Refactor

Test-Driven Development (TDD) is not optional. It is the core of our development process.

1.  **Red:** Write a failing test that defines the desired behavior.
2.  **Green:** Write the minimum amount of code required to make the test pass.
3.  **Refactor:** Improve the design of the code, safe in the knowledge that the tests will catch any regressions.

## 4. The Definition of "Done"

A card is not "Done" until it has met all of the following criteria:

*   The code is merged into the `main` branch.
*   All unit and integration tests are passing.
*   The code coverage is above 90%.
*   The CI/CD pipeline is green.
*   The feature has been deployed to the production environment.
*   The documentation has been updated.

## 5. The Detailed Workflow: From "To Do" to "Done"

1.  **Pick a Card:** Assign a card from the project board to yourself.
2.  **Create a Branch:** Create a feature branch from `develop`.
3.  **Write the Failing Test:** Write a test that proves the feature is not yet implemented.
4.  **Write the Code:** Write the code to make the test pass.
5.  **Run All Local Checks:** Run the linter, all tests, and the code coverage check locally.
6.  **Create a Pull Request:** Create a PR to the `develop` branch.
7.  **The CI/CD Pipeline Runs:** The automated pipeline will run all the checks.
8.  **Code Review:** At least one other developer must review and approve the PR.
9.  **Merge to `develop`:** Once approved and the pipeline is green, merge the PR.
10. **Staging Deployment:** The code is automatically deployed to the staging environment.
11. **QA and UAT:** The QA team and/or the product owner will perform testing in the staging environment.
12. **Release:** Once the staging environment is verified, a release branch is created and deployed to production.
