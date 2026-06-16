# LocalSync — Neighborhood Synchronization App

LocalSync is a community platform designed to connect neighborhoods, enable sharing resources, broadcast emergency alerts, and provide hyperlocal tools.

## Repository Structure

The project is organized into two primary subdirectories:

### 1. `frontend/`
Contains the **Flutter** mobile and web application codebase.
- **Key Modules**: Dashboard, Weather, Notices, SOS Emergency, Marketplace, Business Directory, Rentals, Chat, and User Profiles.
- **Development**: Run `flutter pub get` and standard Flutter build/run commands from within the `frontend/` directory.

### 2. `backend/`
Contains Firebase configuration and testing infrastructure.
- **Security Rules**: `firestore.rules` and `storage.rules` define remote security configurations.
- **Automated Testing Suite**: Located under `backend/testing/`, including:
  - `selenium-tests/` — E2E browser behavior & functional UI assertions.
  - `appium-testing/` — Mobile native behavior & device assertions.
  - `automated-testing/` — Firebase security rules vulnerabilities scanner.
- **Master Reports**: Run consolidation from `backend/testing/` to generate `consolidated_real_test_report.xlsx`.
