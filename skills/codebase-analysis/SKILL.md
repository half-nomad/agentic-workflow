---
name: codebase-analysis
description: "Systematic codebase exploration and understanding"
---

# Codebase Analysis Skill

Systematically understand and document codebase structure.

## When to Use
- Onboarding to new project
- Before major refactoring
- Understanding dependencies
- Architecture documentation

## Analysis Protocol

### Phase 1: Structure Overview

**Entry Points:**
```
Glob("**/index.{ts,js,tsx,jsx}")
Glob("**/main.{ts,js}")
Glob("**/{app,server}.{ts,js}")
```

**Configuration:**
```
Read("package.json")
Read("tsconfig.json")
Read(".env.example")
Glob("**/*.config.{ts,js}")
```

### Phase 2: Architecture Mapping

**Directory Analysis:**
```
src/
├── components/    # UI components
├── hooks/         # React hooks
├── services/      # API/business logic
├── utils/         # Helpers
├── types/         # TypeScript types
└── pages/         # Routes/pages
```

**Key Patterns:**
- How is state managed?
- How is data fetched?
- How is routing handled?
- How are errors handled?

### Phase 3: Dependency Analysis

**External Dependencies:**
```bash
# Check package.json dependencies
# Identify major frameworks
# Note version constraints
```

**Internal Dependencies:**
```
# Map imports between modules
# Identify circular dependencies
# Find shared utilities
```

### Phase 4: Documentation

**Output Format:**
```markdown
# Codebase Analysis: [Project Name]

## Overview
- **Framework**: [e.g., Next.js 14]
- **Language**: [e.g., TypeScript 5.x]
- **Package Manager**: [e.g., pnpm]

## Architecture
[High-level description]

## Directory Structure
[Tree with descriptions]

## Key Patterns
- **State Management**: [approach]
- **Data Fetching**: [approach]
- **Styling**: [approach]

## Entry Points
- [path]: [purpose]

## Important Files
- [path]: [purpose]

## Dependencies
### Critical
- [package]: [purpose]

### Development
- [package]: [purpose]
```

## Checklist
- [ ] Entry points identified
- [ ] Directory structure mapped
- [ ] Key patterns documented
- [ ] Dependencies cataloged
- [ ] README reviewed
