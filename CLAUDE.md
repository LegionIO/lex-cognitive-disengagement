# lex-cognitive-disengagement

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Strategic withdrawal engine based on Wrosch et al. goal disengagement theory. Detects sunk cost bias, assesses opportunity cost, and recommends disengagement from low-progress goals. Models the healthy cognitive capacity to release goals that are not yielding progress — crucial for avoiding the sunk cost fallacy and freeing cognitive resources.

## Gem Info

- **Gem name**: `legion-extensions-cognitive-disengagement` (gemspec name; gem dir is `lex-cognitive-disengagement`)
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveDisengagement`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_disengagement/
  cognitive_disengagement.rb
  version.rb
  client.rb
  helpers/
    constants.rb
    disengagement_engine.rb
    goal.rb
  runners/
    cognitive_disengagement.rb
```

## Key Constants

From `helpers/constants.rb`:

- `GOAL_STATES` — `%i[active monitoring stalled disengaging disengaged]`
- `DISENGAGE_REASONS` — `%i[sunk_cost low_progress opportunity_cost goal_conflict resource_exhaustion external_block]`
- `STATE_LABELS` — state -> label mapping: `active: :pursuing`, `monitoring: :watching`, `stalled: :struggling`, `disengaging: :withdrawing`, `disengaged: :released`
- `MAX_GOALS` = `100`, `MAX_HISTORY` = `300`
- `STALL_THRESHOLD` = `0.1` (progress per check below this = stalled)
- `DISENGAGE_THRESHOLD` = `0.05` (sustained low progress triggers disengagement recommendation)
- `SUNK_COST_WEIGHT` = `0.3`, `OPPORTUNITY_COST_WEIGHT` = `0.4`, `PROGRESS_WEIGHT` = `0.3`
- `DECAY_RATE` = `0.02`

## Runners

All methods in `Runners::CognitiveDisengagement`:

- `create_disengagement_goal(label:, domain:)` — registers a goal for progress monitoring
- `check_goal_progress(goal_id:, new_progress:, effort: 0.1)` — reports current progress; engine computes delta and updates state
- `assess_goal_disengagement(goal_id:)` — returns disengagement assessment: score, recommendation, contributing factors (sunk cost, opportunity cost, progress)
- `disengage_from_goal(goal_id:, reason:)` — explicitly disengages from goal; records reason
- `stalled_goals_report` — all goals in `:stalled` state
- `active_goals_report` — all goals in `:active` state
- `most_invested_goals(limit: 5)` — goals with most cumulative effort (sunk cost indicators)
- `highest_disengage_candidates(limit: 5)` — goals with highest disengagement score
- `update_cognitive_disengagement` — periodic decay cycle + stats
- `cognitive_disengagement_stats` — engine summary

## Helpers

- `DisengagementEngine` — manages goals and history. Disengagement score = weighted combination of sunk cost ratio, opportunity cost signal, and progress delta.
- `Goal` — has `label`, `domain`, `state`, `progress`, `investment` (cumulative effort), `stall_count`. State machine: `active` -> `monitoring` -> `stalled` -> `disengaging` -> `disengaged`.

## Integration Points

- `lex-cognitive-control` manages goal priority and suspension; disengagement handles the harder decision of full abandonment when progress is genuinely blocked.
- `lex-cognitive-debt` accumulates debt for unresolved goals; disengaging from a goal should trigger debt repayment or write-off for that goal's associated debts.
- `update_cognitive_disengagement` is the natural periodic runner — calls decay on all goals and returns current state.

## Development Notes

- Gemspec `spec.name` is `legion-extensions-cognitive-disengagement` (not `lex-cognitive-disengagement`) — this is an inconsistency from the original file. The module path and directory name are correct.
- Gemspec uses `spec.files = Dir['lib/**/*']` — no git ls-files dependency.
- Disengagement score balances three factors with weights summing to 1.0: sunk_cost (0.3), opportunity_cost (0.4), progress_inverse (0.3). Opportunity cost is weighted highest — sunk cost bias should be overcome by future value.
- `assess_goal_disengagement` returns a recommendation (`should_disengage: true/false`) but does not auto-disengage — caller must explicitly call `disengage_from_goal`.
