# MineGuard Mobile App

MineGuard Mobile App is the mobile interface of the MineGuard IoT solution.  
It is designed for mine operators and supervisors who need to access vehicle assignment, performance indicators, safety alerts and profile settings from a mobile device.

## Main Features

- Worker authentication through the mobile login flow.
- Vehicle selection and trip start for operators.
- Operator performance visualization.
- Supervisor alert review.
- Profile and settings access.
- Secure JWT storage using Flutter Secure Storage.
- HTTP communication with the backend through Dio.
- State management using Riverpod.

## Architecture Overview

The project follows a modular structure inspired by Domain-Driven Design.

Each bounded context is organized into:

- `api`: dependency providers.
- `application`: application layer.
- `domain`: entities, interfaces and business rules.
- `infrastructure`: data sources, DTOs and repository implementations.
- `presentation`: screens, controllers and widgets.

## Main Modules

| Module | Purpose |
|---|---|
| `iam` | Handles authentication and session creation. |
| `assets` | Handles vehicle selection and trip start. |
| `analytics` | Displays operator performance indicators. |
| `monitoring` | Displays and manages supervisor safety alerts. |
| `profile` | Contains profile and settings screens. |
| `shared` | Provides common models, network client, colors and reusable widgets. |

## Backend Configuration

The API base URL is configured using `API_BASE_URL`.

Default value:

```bash
http://10.0.2.2:8080/api/v1