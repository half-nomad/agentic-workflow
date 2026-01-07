---
alwaysApply: true
description: "Global coding and workflow rules that always apply"
---

# Global Rules

## Code Quality

### Simplicity First
- Prefer simple solutions over clever ones
- Don't add features that weren't requested
- Remove code rather than commenting it out
- One thing should do one thing

### Clean Code
- Self-documenting code over comments
- Meaningful names for variables and functions
- Small, focused functions
- Consistent formatting

### Comments
Only add comments when:
- Explaining WHY (not what)
- Complex business logic
- Non-obvious workarounds
- API documentation (public interfaces)

Never comment:
- Obvious code
- Commented-out code (delete it)
- TODO without ticket reference

## Workflow

### Before Coding
1. Understand the requirement fully
2. Check existing patterns in codebase
3. Plan the approach

### During Coding
1. Make small, atomic changes
2. Test each change
3. Keep commits focused

### After Coding
1. Verify the change works
2. Check for unintended side effects
3. Update documentation if needed

## Communication

### Be Concise
- Dense and useful beats long and thorough
- Lead with the answer, then explain
- Use lists over paragraphs

### Be Precise
- Include file paths with line numbers
- Provide working code examples
- State assumptions explicitly
