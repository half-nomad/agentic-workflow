---
globs:
  - "**/*.ts"
  - "**/*.tsx"
description: "TypeScript-specific coding rules"
---

# TypeScript Rules

## Type Safety

### Strict Mode
- Always use `strict: true` in tsconfig
- No `any` unless absolutely necessary (and documented why)
- Prefer `unknown` over `any` for unknown types

### Type Definitions
```typescript
// Good: Interface for objects
interface User {
  id: string
  name: string
}

// Good: Type for unions/intersections
type Status = 'pending' | 'active' | 'completed'

// Bad: any
const data: any = fetchData()

// Good: proper typing
const data: User[] = await fetchUsers()
```

### Null Handling
```typescript
// Use optional chaining
const name = user?.profile?.name

// Use nullish coalescing
const value = input ?? defaultValue

// Avoid non-null assertion unless certain
// Bad: user!.name
// Good: if (user) { user.name }
```

## Code Style

### Functions
```typescript
// Prefer arrow functions for callbacks
const items = list.map((item) => item.value)

// Use explicit return types for public functions
function processUser(user: User): ProcessedUser {
  // ...
}

// Avoid default exports
export { MyComponent }  // Good
export default MyComponent  // Avoid
```

### Imports
```typescript
// Group imports: external, internal, relative
import { useState } from 'react'

import { useAuth } from '@/hooks'

import { Button } from './Button'
```

### Async/Await
```typescript
// Always handle errors
try {
  const result = await fetchData()
} catch (error) {
  if (error instanceof ApiError) {
    // Handle API error
  }
  throw error
}

// Parallel when independent
const [users, posts] = await Promise.all([
  fetchUsers(),
  fetchPosts()
])
```

## Patterns

### Error Handling
```typescript
// Define custom errors
class ValidationError extends Error {
  constructor(
    message: string,
    public field: string
  ) {
    super(message)
    this.name = 'ValidationError'
  }
}
```

### Type Guards
```typescript
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'name' in value
  )
}
```
