# SIP Sistem Absensi


Sistem Absensi PT Selada Indonesia Produktif merupakan aplikasi yang dirancang untuk membantu proses pencatatan kehadiran pegawai secara digital. Sistem ini mendukung pencatatan absensi menggunakan NFC serta menyediakan dashboard monitoring secara real-time, aplikasi mobile untuk pegawai, dan web admin untuk pengelolaan data.

## Repository Structure

```
sip-sistem-absensi/
│
├── backend/         # Backend API
├── mobile/          # Mobile Application
├── web-admin/       # Web Application for Administrator
├── tv-dashboard/    # Real-time Dashboard for TV Display
├── docs/            # Project Documentation
│
├── README.md
└── CONTRIBUTING.md
```

## Branch Strategy

| Branch | Description |
|---------|-------------|
| `main` | Stable branch / Production |
| `develop` | Main development branch |
| `feature/*` | Feature development |
| `hotfix/*` | Emergency bug fixes (if needed) |

## Development Workflow

```
feature/*
   │
   ▼
develop
   │
   ▼
main
```

## Documentation

Project documentation will be stored inside the `docs/` directory, including:

- Git Workflow
- Branch Strategy
- Deployment Plan
- Environment Configuration
- Docker Guide
- CI/CD Plan

## Project Status

🚧 Currently in Requirement Analysis & System Design Phase.

Development, deployment, and CI/CD configuration will be implemented in the next project phases.

## Team

KP/PKL PT Selada Indonesia Produktif
