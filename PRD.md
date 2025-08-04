# PRODUCT REQUIREMENT DOCUMENT

**Project:** Context 7 MCP Docker Integration for Claude Code (Phase 4a)
**Version:** 1.0.0 - COMPLETED
**Owner:** @jack • **Tech‑Lead:** @tldr\_engineer
**Status:** Production Ready
**Last Edited:** 2025‑08‑03

## 1 Summary

Deliver a one-command, Docker-packaged **Context 7 MCP** server that Claude Code (v1.0.65) can access via **user-scoped registration** to fetch live library documentation in chat sessions with ≤ 10 second response times, zero host pollution, and event-driven container lifecycle, on an Apple-silicon MacBook Pro.

**Key Success**: Context7 tools appear as native functions in **fresh Claude Code chat sessions** after user-scope registration.

### Reference Docs

• Context‑7 repo: [https://github.com/upstash/context7](https://github.com/upstash/context7)
• MCP spec: [https://modelcontextprotocol.io/introduction](https://modelcontextprotocol.io/introduction)
• Claude Code MCP CLI excerpt (internal link)

---

## 2 Goals & Success Metrics

| Goal                   | Metric                                 | Target   | Owner   |
| ---------------------- | -------------------------------------- | -------- | ------- |
| **Chat Integration**   | Context7 tools available in new sessions | 100%     | Eng     |
| **Fast docs**          | p95 resolve‑library‑id → first byte    | ≤ 200 ms | Eng     |
| **Isolation**          | Host files written outside project dir | 0        | SecOps  |
| **Reproducible build** | SHA variance across rebuilds           | 0        | Dev‑Ops |
| **Low setup friction** | Makefile targets to working Claude     | ≤ 3      | DevRel  |

---

## 3 Scope

### 3.1 In‑Scope

* Docker image `context7-mcp:1.0` built from pinned `@upstash/context7-mcp@1.0.x`.
* Makefile with `setup` and `run` targets.
* Claude Code registration via STDIO with hard limits `--memory 2g --cpus 1`.
* Container must appear in **Docker Desktop → Containers** pane while running.
* Secrets support via Docker secret file `context7-secret.txt` (optional).

### 3.2 Out‑of‑Scope

* Persistent cache.
* Additional MCPs (Sequential, Magic, Playwright).
* Slash‑command agents, proxy, CI runners, Windows/Linux builds.

### 3.3 Future

* Add persistent cache and cache‑purge commands.
* Docker‑compose bundle with Sequential MCP.
* CI Arm64 build & security patch automation.

---

## 4 Personas & Use Cases

| Persona          | Job‑to‑be‑Done                                                                        |
| ---------------- | ------------------------------------------------------------------------------------- |
| Solo Dev (Jack)  | Ask Claude for accurate API docs; confirm MCP container is running in Docker Desktop. |
| Solo Dev (Jack)  | Ask Claude Code chat window to search using context/7 MCP. |
| Security Auditor | Verify container network scope & lifecycle from Docker Desktop UI.                    |

---

## 5 Functional Requirements

1. **Container spawn & visibility** – When Claude requests docs, it spawns the Docker command via STDIO **and the container is visible in Docker Desktop** under the name `context7-mcp`.
2. **Zero host writes** – Container writes only to ephemeral filesystem; no volumes mounted.
3. **Resource guard** – Container obeys `2 GB / 1 CPU` limits.
4. **Version pinning** – Build locks MCP minor version; manual bumps only.
5. **Secrets option** – If `context7-secret.txt` exists, it is mounted as Docker secret.

---

## 6 Edge Cases & Error Handling

| Event             | Handler                                                                                    |
| ----------------- | ------------------------------------------------------------------------------------------ |
| Network offline   | MCP returns 5xx; Claude chat displays “Docs unavailable – check connection”.               |
| Image missing     | Setup script prompts user to run `make setup`.                                             |
| MCP not reachable | Claude chat surfaces `Context7 error: connection refused`; prompts user to run `make run`. |

---

## 7 Non‑Functional Requirements

* **Performance:** p95 doc fetch ≤ 200 ms.
* **Security:** Non‑root container; outbound HTTPS only to GitHub/GitLab raw content; optional secret via Docker secrets.
* **Portability:** Runs native on `linux/arm64` & `linux/amd64` images.
* **Logging:** Basic stdout; errors surfaced to Claude chat with prefix `Context7 error:`.

---

## 8 Technical Design & Constraints

### 8.1 Folder Layout

```
/Users/jack/Developer/MCPs/
└── context7-mcp/   # build context & Makefile
```

### 8.2 Dockerfile (arm‑native, non‑root)

```dockerfile
FROM node:20-alpine
WORKDIR /app
RUN npm install -g --omit=dev @upstash/context7-mcp@1.0.x \
 && addgroup -S app && adduser -S app -G app \
 && chown -R app:app /app
USER app
ENTRYPOINT ["context7-mcp"]
```

### 8.3 Makefile Targets

```make
setup:   ## Build local Docker image
	docker build -t context7-mcp:1.0 .

run:     ## Register MCP with Claude and start container on demand
	claude mcp add context7 -- docker run -i --rm --name context7-mcp --memory 2g --cpus 1 context7-mcp:1.0
```

### 8.4 Config & Constraints

| Layer      | Detail                                                               |
| ---------- | -------------------------------------------------------------------- |
| Base image | `node:18-alpine` multi‑arch (native ARM on M2)                       |
| Secrets    | Mounted to `/run/secrets/context7-secret.txt` if provided            |
| Visibility | Container named `context7-mcp` so it shows clearly in Docker Desktop |
| Logging    | Stdout; Claude surfaces messages prefixed `Context7 error:`          |

---

## 9 Acceptance Criteria

| ID       | Scenario                 | Given             | When                                                 | Then                                                                      |
| -------- | ------------------------ | ----------------- | ---------------------------------------------------- | ------------------------------------------------------------------------- |
| **AC‑1** | Docker visibility        | Image cached      | Claude spawns MCP                                    | `context7-mcp` entry appears in Docker Desktop Containers pane within 1 s |
| **AC‑2** | Claude ↔ MCP integration | Container running | Claude chat requests docs (e.g., `get-library-docs`) | Chat returns doc content with no error                                    |
| **AC‑3** | Container shutdown       | Claude idle       | Claude issues `/mcp → Stop` or process exits         | Entry disappears from Docker Desktop within 2 s                           |

---

## 10 Risks & Mitigations

| Risk                      | Mitigation                                                                |
| ------------------------- | ------------------------------------------------------------------------- |
| Node 18 EOL               | Migrate to Node 20‑alpine; rebuild.                                       |
| Context 7 breaking change | Version pin; manual review before bump.                                   |
| Secret mis‑handling       | Doc instructs `docker secret` usage; secret never appears in env or logs. |

---

## 11 Rollback & Observability

* Remove entry in `~/.claude/mcp.json` or disable via settings.
* Delete Docker image.
* Errors surfaced in Claude chat with prefix `Context7 error:`.

---

## 12 Assumptions & Dependencies

* Claude Code v1.0.65 supports STDIO MCP.
* Docker Desktop ≥ 4.30 on macOS 14.
* GitHub raw endpoints are reachable.

---

## 13 Changelog

| Date       | Ver   | Change                                                               |
| ---------- | ----- | -------------------------------------------------------------------- |
| 2025‑08‑03 | 0.3.0 | Added container‑visibility & integration ACs; removed cache from MVP |
