# lex-cognitive-scaffolding

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-cognitive-scaffolding`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::CognitiveScaffolding`

## Purpose

Models skill acquisition through the Zone of Proximal Development (ZPD) framework. Each tracked skill (scaffold) has a competence level and support tier. Attempting tasks updates competence: success in the ZPD yields full `LEARNING_GAIN`; success outside the ZPD yields half gain; failure causes a `FAILURE_SETBACK`. Support level fades automatically on success and increases on failure. This models how an agent's need for external scaffolding decreases as mastery grows.

## Gem Info

- **Gemspec**: `lex-cognitive-scaffolding.gemspec`
- **Require**: `lex-cognitive-scaffolding`
- **Ruby**: >= 3.4
- **License**: MIT
- **Homepage**: https://github.com/LegionIO/lex-cognitive-scaffolding

## File Structure

```
lib/legion/extensions/cognitive_scaffolding/
  version.rb
  helpers/
    constants.rb           # ZPD bounds, support levels, learning/decay rates, zone labels
    scaffold.rb            # Scaffold class — one tracked skill with competence and support
    scaffolding_engine.rb  # ScaffoldingEngine — registry and aggregate queries
  runners/
    cognitive_scaffolding.rb  # Runner module — public API
  client.rb
```

## Key Constants

| Constant | Value | Meaning |
|---|---|---|
| `MAX_SCAFFOLDS` | 100 | Hard cap on tracked skills |
| `MAX_TASKS` | 500 | Max task attempts (defined, not currently enforced) |
| `MAX_HISTORY` | 300 | Task history ring size per scaffold |
| `DEFAULT_COMPETENCE` | 0.3 | Starting competence for new scaffolds |
| `ZPD_LOWER` | 0.3 | Lower bound of Zone of Proximal Development |
| `ZPD_UPPER` | 0.8 | Upper bound of ZPD |
| `MASTERY_THRESHOLD` | 0.85 | Competence >= this = mastered |
| `FRUSTRATION_THRESHOLD` | 0.15 | Reference threshold (defined, not enforced) |
| `LEARNING_GAIN` | 0.08 | Competence increase per successful ZPD attempt |
| `FAILURE_SETBACK` | 0.03 | Competence decrease per failed attempt |
| `FADING_RATE` | 0.1 | Reference rate for scaffolding fade (defined, not used in decay) |
| `DECAY_RATE` | 0.01 | Competence decay per `decay_all` tick (skips mastered skills) |

Zone labels: `0.85+` = `:mastered`, `0.3..0.85` = `:zpd`, `<0.3` = `:beyond_reach`

Support levels (ordered most to least support): `[:full, :guided, :prompted, :independent]`

## Key Classes

### `Helpers::Scaffold`

A single tracked skill with competence, support level, and task history.

- `attempt_task(difficulty:, success:)` — updates competence, increments `practice_count`, calls `adjust_support`, records to `task_history`
- `current_zone` — `:mastered`, `:zpd`, or `:beyond_reach`
- `recommended_difficulty` — midpoint between current competence and `ZPD_UPPER`
- `fade_support!` — moves one step toward `:independent` (called on success)
- `increase_support!` — moves one step toward `:full` (called on failure)
- `mastered?` — competence >= `MASTERY_THRESHOLD`
- `in_zpd?` — competence in `[ZPD_LOWER, ZPD_UPPER)`
- Initial support level: `competence >= ZPD_UPPER` -> `:independent`, `>= ZPD_LOWER` -> `:prompted`, else `:full`
- Task history is a ring buffer capped at `MAX_HISTORY`; each entry has `{ task_id:, difficulty:, success:, support:, at: }`

Learning delta: success in ZPD = `+LEARNING_GAIN`, success outside ZPD = `+LEARNING_GAIN / 2`, failure = `-FAILURE_SETBACK`.

### `Helpers::ScaffoldingEngine`

Registry and aggregate operations for all scaffolds.

- `create_scaffold(skill_name:, domain:, competence:)` — trims before creating if at `MAX_SCAFFOLDS`
- `attempt_scaffolded_task(scaffold_id:, difficulty:, success:)` — delegates to `Scaffold#attempt_task`; returns nil if not found
- `recommend_task(scaffold_id:)` — returns `{ difficulty:, support_level:, zone: }` or nil
- `mastered_skills` / `zpd_skills` — filtered lists of scaffold objects
- `by_domain(domain:)` — all scaffolds matching a domain
- `adjust_support(scaffold_id:, direction:)` — `:increase` or `:decrease` (`:decrease` calls `fade_support!`)
- `overall_competence` — mean competence across all scaffolds
- `decay_all` — subtracts `DECAY_RATE` from all non-mastered scaffolds via `instance_variable_set`
- `trim_scaffolds` (private) — evicts oldest mastered skill (or oldest skill if none mastered) when at capacity

## Runners

Module: `Legion::Extensions::CognitiveScaffolding::Runners::CognitiveScaffolding`

| Runner | Key Args | Returns |
|---|---|---|
| `create_scaffold` | `skill_name:`, `domain:`, `competence:` | `{ success:, scaffold: }` |
| `attempt_scaffolded_task` | `scaffold_id:`, `difficulty:`, `success:` | `{ success:, scaffold: }` or `{ success: false, reason: :not_found }` |
| `recommend_scaffolded_task` | `scaffold_id:` | `{ success:, recommendation: }` or not found |
| `mastered_scaffolded_skills` | — | `{ success:, skills:, count: }` |
| `zpd_skills` | — | `{ success:, skills:, count: }` |
| `domain_scaffolds` | `domain:` | `{ success:, domain:, scaffolds:, count: }` |
| `adjust_scaffold_support` | `scaffold_id:`, `direction:` | `{ success:, scaffold: }` or not found |
| `overall_scaffolded_competence` | — | `{ success:, overall_competence: }` |
| `update_cognitive_scaffolding` | — | `{ success:, action: :decay, scaffold_count:, overall_competence: }` |
| `cognitive_scaffolding_stats` | — | `{ success:, stats: }` from `engine.to_h` |

No `engine:` injection keyword. Engine is a private memoized `@engine`.

## Integration Points

- No actors defined; `update_cognitive_scaffolding` is designed to be called by an external scheduler (e.g., `lex-tick` decay phase)
- Can be paired with `lex-cognitive-reserve` for a fuller capability model: reserve tracks pathway capacity, scaffolding tracks skill competence
- `recommend_scaffolded_task` provides optimal difficulty targeting — feeds into task selection or `lex-volition`
- All state is in-memory per `ScaffoldingEngine` instance

## Development Notes

- `MAX_TASKS` and `FRUSTRATION_THRESHOLD` are defined as constants but not used in the current implementation
- `decay_all` uses `instance_variable_set(:@competence, ...)` to mutate scaffold competence directly, bypassing `attempt_task`
- `adjust_support(direction: :decrease)` calls `fade_support!`; `:increase` calls `increase_support!`
- The scaffold ID is a UUID string (from `SecureRandom.uuid`), unlike other engines that use sequential symbols
- `trim_scaffolds` prefers to evict mastered skills over non-mastered ones, keeping active learners
