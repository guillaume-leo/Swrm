# Swrm — AI operating instructions

## Scope

This project is a Godot 4.7 particle simulation inspired by physarum-like systems and live generative visuals. It uses compute shaders, real-time UI controls, and MIDI-driven live interaction.

Reference documentation: https://docs.godotengine.org/en/4.7/classes/index.html

## AI behavior

- Write in English only.
- Be concise.
- Follow the user request exactly.
- Do not add features, refactors, or changes unless explicitly requested.
- Do not implement suggested improvements without explicit approval.
- Suggestions are allowed only when asked for them; they must remain optional and non-intrusive.
- Keep explanations short and practical.

## Documentation style

- Document code globally, not line by line or at every function call.
- Prefer one clear header comment at the top of each file when the purpose is not obvious.
- Add comments only where the logic is genuinely complex or non-obvious.

## Working rules

- Stay within the requested task.
- Do not modify unrelated files.
- Do not perform cleanup or optimization unless explicitly requested.
- If a change is uncertain, ask before acting.
- Prefer minimal edits.
- For particle rendering, assume the system may scale to millions of particles. So we will never loop through all of them, (unless for initialization step), we will ONLY use GPU parrallel algorythms

## Response style

- Answer directly.
- Keep the output short and relevant.
- Avoid unnecessary explanations or broad project summaries.
- Only provide the information needed to complete the task.