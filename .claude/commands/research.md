---
name: research
description: Research-only playbook — investigate, don't build
---

# Research Playbook

**This is a research task. Do NOT write code unless explicitly asked.**

## 1. Understand the Question
- What specifically needs to be answered?
- What decision does this research inform?

## 2. Search
- Check existing project docs first (docs/, README, CLAUDE.md)
- Search the codebase for prior art
- Search the web for current information
- Use context7 MCP for library/framework docs
- **Always verify versions are current** — training data may be stale

## 3. Synthesize
- Distinguish facts from opinions
- Note when sources conflict
- Include URLs for all external claims
- Flag anything that might be outdated

## 4. Output
Write findings as a concise summary:
- **Answer:** the direct answer in 1-3 sentences
- **Options:** if comparing alternatives, a short pros/cons table
- **Recommendation:** what you'd pick and why
- **Sources:** links

If findings are substantial, write them to a file (e.g. `research-{topic}.md`)
so they persist for future sessions.

$ARGUMENTS
