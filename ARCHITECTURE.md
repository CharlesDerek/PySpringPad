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


---

Identity- & State-Aware Security (Next-Gen Firewall–Inspired)

Goal

Provide L7, identity-aware, policy-driven protection analogous to a Next Generation Firewall (NGFW), but embedded in the generated app/platform. Policies are declarative, enforced by Policy Enforcement Points (PEPs) at your API/UI/Job boundaries, with decisions made by a Policy Decision Point (PDP) using user/device/session context. Works in stateless (JWT/OIDC) and stateful (server sessions, device posture, risk score) modes.


---

Components

1) Policy Decision Point (PDP)

Evaluates RBAC/ABAC rules and risk signals (IP reputation, device posture, geo-velocity).

Consumes identity claims (OIDC/SAML), session data, and request attributes.

Exposed as a library (security.pdp) with a sidecar option for out-of-process evaluation.


2) Policy Enforcement Points (PEPs)

API PEP: framework middleware (Flask/FastAPI/Django) guarding every route/resource.

Frontend PEP: React guards for routes/components; mirrors server decisions (defense-in-depth).

Job/Queue PEP: validates producer/consumer identities and message scopes.

Data PEP (optional): guards DAO/repository calls for row/field-level security.


3) Context Providers

Identity: JWT/OIDC tokens, SAML assertions, API keys, service accounts.

Session (stateful): Redis-backed session with rolling expiry, device binding, MFA state.

Signals: rate metrics, anomaly flags, IP/ASN intel, device posture, time-of-day.


4) Policy Store & DSL

Versioned policy bundles (YAML/JSON) kept under security/policies/.

Supports RBAC, ABAC (attributes on user/resource/environment), rate quotas, geo/time fences, and step-up MFA.


5) Telemetry & Audit

Structured logs (PEP allow/deny, reasons), metrics (allow/deny counts, p99 latency), traces.

Tamper-evident audit trail with hash chaining (optional).



---

Stateless vs. Stateful Modes

Stateless: Verify JWT/OIDC per request; embed roles/attrs in claims; optional detached token introspection.

Pros: horizontal scale, minimal server memory.

Cons: limited revocation/restriction without short TTL or introspection.


Stateful: Server-side session (Redis) contains risk score, device fingerprint, consent/MFA state, recent anomalies.

Pros: fine-grained revocation, adaptive policies, richer context.

Cons: needs shared store, adds complexity.



You can enable either or both (stateless primary with stateful augment for high-risk zones).


---

Declarative Manifest Additions

security:
  mode: mixed            # stateless | stateful | mixed
  identity:
    providers: [oidc, saml]   # plus: local, api_key, mtls
    mfa: [totp, webauthn]
  policies:
    bundles:
      - base
      - finance_strict
  dlp:
    enabled: true
    detectors: [pii_email, pii_ssn, cc_pan]
  waf:
    enabled: true
    ruleset: baseline     # app-layer checks, SSRF/SQLi/NoSQLi patterns
  rate_limits:
    default: { window: 60s, max: 600 }
    per_route:
      /api/v1/users: { window: 60s, max: 120 }
  anomaly:
    geo_velocity: enabled
    ip_reputation: enabled

Object-Level Security Declarations

objects:
  - type: api.resource
    name: Users
    entity: User
    version: v1
    crud:
      create: { enabled: true, policy: role>=admin }
      read:   { enabled: true, policy: abac(user.id == ctx.user_id or role>=staff) }
      update: { enabled: true, policy: step_up_mfa(role>=admin) }
      delete: { enabled: restricted, policy: risk_score<50 and role>=admin }
    guards:
      rate_limit: medium
      ip_allowlist: [office_cidr, vpn]
      require_signed_request: false

  - type: external.auth
    name: OrgLogin
    providers: [oidc, saml]
    mfa: webauthn
    session:
      max_age: 8h
      rolling: true
      bind_device: true

Policy DSL (Example Bundle)

bundle: finance_strict
rules:
  - id: FIN-READ
    effect: allow
    when: resource.type == "Invoice" and (
            subject.role in ["admin","finance"] or
            resource.owner_id == subject.sub
          )

  - id: FIN-EXPORT
    effect: deny
    when: action == "export" and env.risk_score >= 70

  - id: STEP-UP
    effect: require_mfa
    when: action in ["delete","elevate_role"] and subject.mfa_verified == false


---

Enforcement Flow

flowchart LR
  A[Request arrives] --> B[Identity Extractor (JWT/OIDC/SAML)]
  B --> C[Context Build (session, risk, device)]
  C --> D[API PEP middleware]
  D --> E[PDP evaluate policies (RBAC/ABAC/DLP/WAF/Rate)]
  E -->|allow| F[Handler/Controller]
  E -->|require_mfa| G[MFA Flow]
  E -->|deny| H[Block + Audit]

WAF/DLP run as fast pre-filters (pattern & content checks) before/alongside PDP.

Rate limits enforced per identity, route, and optional IP/device key.

Step-up prompts are automatic when PDP returns require_mfa.



---

Integration Points (Generated Code)

Flask/FastAPI/Django: drop-in middleware: security.middleware.api_pep.

Repositories: optional security.middleware.data_pep for row/field-level ABAC.

Frontend: React Guard HOC + hooks mirroring PDP decisions and feature flags.

Jobs/Queues: decorators @guarded(action="consume", resource="QueueX").

Config: policies in security/policies/*.yaml; mode toggles via env (12-factor friendly).



---

Performance & Optional Native Path

Hot paths (WAF matchers, DLP detectors, ABAC evaluator) can be C++ modules behind a stable Python interface.

Token verification and rate limiting use O(1) Redis ops with Lua scripts when stateful.

PDP caches compiled policies; supports incremental reload on bundle change.



---

Testing & Audit

Generated security test suite per object (allow/deny/require_mfa cases).

Replayable audit: each decision logs inputs, rule hits, and outcome; hash-chained per request for tamper evidence.

Policy diff in CI to require review for changes impacting critical routes.



---

Why This Matters

Moves security from ad-hoc middleware to a first-class, declarative system.

Gives you NGFW-like identity & context awareness directly at the app layer (L7), not only at the edge.

Scales from simple RBAC to attribute/risk-based access and step-up MFA, with clear auditability.



---

Minimal Code Hook (example, FastAPI)

```
from security.middleware import api_pep
from security.context import build_request_context
from security.pdp import evaluate

@app.middleware("http")
async def guard_request(request, call_next):
    ctx = await build_request_context(request)  # identity + session + signals
    decision = await evaluate(ctx)              # RBAC/ABAC/WAF/Rate/DLP
    if decision.action == "deny":
        return JSONResponse({"error": "forbidden"}, status_code=403)
    if decision.action == "require_mfa":
        return JSONResponse({"mfa": "required"}, status_code=401)
    return await call_next(request)
```



---