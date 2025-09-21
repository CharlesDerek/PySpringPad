#Architecture: Declarative, Stage-Based Build Engine with Object Graphs

Philosophy

This system is a user-declared build engine that produces a polished, production-ready application, not merely a starter scaffold. Users describe what they want; the engine emits the optimal implementation for that exact path—from domain objects to API/CRUD, backend persistence, UI components, and external integrations—optionally transpiling performance-critical parts to C++.

User-Driven (no auto-guessing): The engine does not choose for you; it enforces compatibility and best practices for your selections.

Stage Pipeline: Each stage constrains the next (Paradigm → Architecture → Stack → Infra → Objects → Enhancements → Packaging → Compilation(s) → Network-Configurations → Test(s) → Runtime(s)

Object Graph: Applications are defined as typed objects (API, Backend, Frontend, External, etc.) with nested capabilities (e.g., CRUD, Auth, SSO, MFA, caching).

Polished Output: Generates finished code, tests, docs, CI/CD, Docker, infra config, and UX components—ready to run and ship.



---

Stages (Deterministic Pipeline)

1. Paradigm: oop | functional | event-driven


2. Architecture: monolith | modular-service | microservices


3. Stack: flask | fastapi | django (+ ORM/patterns per stack)


4. Infra: object storage, databases, queues, caches, search, mailers


5. Object Graph: declarative “objects” (API/Backend/Frontend/External) with nested features


6. Enhancements: GC helpers, profiling, rate limits, RBAC/ABAC, observability


7. Packaging: Docker/Compose, CI/CD, Make targets, Helm (optional)


8. Language Target (optional): transpile selected modules to appropriate compiled builds with appropriate libs, etc.



Each stage validates the configuration and exports bindings (interfaces, adapters, configs) for downstream stages.


---

The Object Model

Object Types

API Objects: define resources, versions, routes, CRUD policies, validation, pagination, error models, OpenAPI.

Backend Objects: domain entities, repositories, services, aggregates, transactions, migrations.

Frontend Objects: component specs (React by default), forms, tables, dashboards, access control guards.

External Objects: SSO/SAML/OIDC, MFA providers, SMTP, object storage (S3), payments, webhooks, search.

System Objects: jobs/schedulers, queues, telemetry, feature flags.


Objects can nest (e.g., User with LoginPolicy, Profile with AvatarStorage) and relate (e.g., Invoice→LineItem).

Example Manifest (Declarative)

name: vision-scout
paradigm: oop
architecture: monolith
stack:
  web: flask
  orm: sqlmodel
infrastructure:
  database: postgres
  cache: redis
  storage: aws_s3
  messaging: none
objects:
  - type: backend.entity
    name: User
    fields:
      - {name: id, type: uuid, primary: true}
      - {name: email, type: email, unique: true, index: true}
      - {name: hashed_password, type: secret}
      - {name: role, type: enum[admin,staff,viewer], default: viewer}
    policies:
      auth: local
      audit: enabled
      soft_delete: true

  - type: api.resource
    name: Users
    entity: User
    crud:
      create: {enabled: true, input: dto}
      read:   {enabled: true, filter: by_email|by_role, pagination: cursor}
      update: {enabled: true, partial: true}
      delete: {enabled: restricted, policy: role>=admin}
    version: v1
    openapi: true

  - type: frontend.component
    name: UsersTable
    binds_to: Users
    features: [filter, sort, paginate, inline-edit]

  - type: external.auth
    name: OrgLogin
    providers: [saml, oidc]
    mfa: totp
    user_mapping:
      idp_email_claim: email
      default_role: viewer

enhancements:
  garbage_collection: enabled
  profiling: basic
  observability: prometheus+otel
packaging:
  docker: compose
  ci: github_actions
language_target:
  cpp:
    modules: [crypto, hot_paths.services.UserService]


---

Build Semantics

Graph-Oriented Resolution (Deterministic)

The Object Graph is a directed acyclic graph (DAG) of typed nodes.

Edges represent dependencies (e.g., api.resource.Users → backend.entity.User → postgres).

Each node renders code through a template strategy bound to the current Stage selections.

Invalid combos are rejected early with actionable diagnostics.


Prompt-Assisted Completion (Optional)

For underspecified objects, the CLI can prompt for missing fields (types, policies, relations).

Prompts are schema-aware (it won’t suggest options outside the allowed strategy set).

You can lock the run with --no-prompt for fully noninteractive CI/CD.



---

Output Guarantees (Polished App)

API: versioned routes, OpenAPI, error handling, pagination, auth guards, request/response DTOs.

Backend: entities, repositories, services, transactions, migrations (Alembic), seed scripts.

Frontend: React components (table/form/detail), routing, auth guards, state/query hooks.

External: SAML/OIDC/OAuth provider setup, MFA flow, secrets wiring.

Operational: logging (structured), metrics (Prometheus), tracing (OTel), health checks.

DevEx: make dev, make test, make migrate, make seed, hot reload (where supported).

Quality: ruff/black/mypy preconfigured; unit/integration test stubs; coverage.

Packaging: Dockerfiles, docker-compose, GitHub Actions (build/test/lint), .env.example.

Docs: project README, runbooks, API docs served at /docs.



---

Python → C++ Conversion (Selective)

For hot paths, the Language Target stage can emit C++ from Python designs:

Approaches (choose per module):

Pybind11 / PyO3 for extension modules.

Cython for typed Python → C/C++ speedups.

Custom codegen from Python AST/type info → C++ classes using STL/Boost or domain libraries.


Contract: keep domain/service interfaces stable; provide adapter shims on the Python side.

Build: generated C++ placed under cpp/, compiled into an extension wheel via maturin/setuptools, wired automatically.



---

Internal Components

Kernel (CLI + Orchestrator): Typer/Click command hub; runs the stage pipeline.

Manifest Engine: schema validation, defaults, compatibility checks.

Object Registry: typed object loaders, relation validator, graph builder.

Template Engine: Jinja2 (or CUE/ytt) for multi-target rendering; file ops are streaming.

Strategy Plugins:

stack/* (flask, fastapi, django)

infra/* (postgres, redis, s3, kafka, mail, search)

auth/* (local, saml, oidc, oauth, mfa)

frontend/* (react tables/forms/layout)

language/* (py, cpp)


Post-Processors: import sorting, formatting, test hydration, migration synthesis.



---

Mermaid Diagrams (drop-in)

1) Stage Pipeline

flowchart LR
  P[Paradigm] --> A[Architecture]
  A --> S[Stack]
  S --> I[Infra]
  I --> O[Object Graph]
  O --> E[Enhancements]
  E --> K[Packaging]
  K -->|opt| C[Language Target: C++]

2) Object Graph (Example)

graph TD
  U[backend.entity: User] --> R[api.resource: Users v1]
  U --> A[external.auth: OrgLogin]
  R --> F[frontend.component: UsersTable]
  U --> D[(postgres)]
  A --> S[(saml/oidc)]
  F --> UI[React Router / Guards]


---

Developer Workflow

# 1) Create a manifest
pyspringpad init --name vision-scout

# 2) Add objects (declarative)
pyspringpad add entity User --fields id:uuid,email:email,hashed_password:secret,role:enum(admin,staff,viewer)

pyspringpad add api Users --entity User --crud create,read,update,delete \
  --filters by_email,by_role --pagination cursor --version v1 --openapi

pyspringpad add frontend UsersTable --bind Users --features filter,sort,paginate,inline-edit

pyspringpad add external auth OrgLogin --providers saml,oidc --mfa totp

# 3) Select stack & infra
pyspringpad select stack flask --orm sqlmodel
pyspringpad select infra postgres redis aws_s3

# 4) Generate polished app
pyspringpad build --prompt   # or --no-prompt in CI

# 5) (Optional) Transpile select modules to C++
pyspringpad target cpp --modules crypto,services.UserService


---

Why Employers Care

End-to-End Delivery: Not just “hello world”—it ships APIs, DB, UI, auth, tests, CI, and ops.

Declarative Platform Thinking: Shows you can design pipelines that scale across orgs.

Correctness by Construction: Stages and object types enforce compatibility and quality gates.

Performance Path: Clear story for moving hot paths to native C++ while preserving interfaces.

Maintainability: Hexagonal boundaries inside generated code; strict typing and tests from day one.



---

Roadmap

More object kinds (reports, realtime streams, feature flags, workflows).

Visual graph inspector (pyspringpad graph --view).

Blueprints (pre-set bundles for “Admin App”, “Billing API”, “IoT Ingest”).

Cross-cloud infra adapters; Helm/Kustomize emits.

Richer Python→C++ codegen (AST-driven with ownership/memory models).

---

Declarative Yet Unopinionated by Default

The system is declarative at its core: users describe what they want, and the engine constructs exactly that.

Unopinionated Base

By default, no framework conventions or “best practice” overlays are imposed.

If the manifest requests a monolith with Flask + MongoDB + custom auth, the engine scaffolds precisely that—no substitutions.

This ensures advanced users have full control and reproducibility.


Opinionated Overlays (Optional)

Conventions (e.g., 12-factor app defaults, CI/CD presets, observability hooks) can be applied through optional helpers or plugins.

These overlays are modular: they can be swapped in, combined, or ignored.


Future Guided Mode

With helper libraries or MCP/LLM integration, the engine could suggest opinionated defaults:

“Add Alembic migrations for Postgres?”

“Enable JWT auth with refresh tokens?”

“Add Prometheus metrics and health checks?”


Users can choose to accept or decline suggestions, keeping the workflow deterministic and user-controlled.



This dual approach means the system can serve both:

1. Strict declarative builders who want a non-opinionated, fully controllable pipeline.


2. Teams that prefer conventions or guided scaffolding with best-practice defaults.
