# lex-cognitive-disengagement

Goal disengagement and sunk cost detection for LegionIO cognitive agents.

## What It Does

Strategic withdrawal based on Wrosch et al. goal disengagement theory. When a goal stops making progress, cognitive resources are better spent elsewhere — but the sunk cost fallacy makes it hard to let go. This extension tracks goal progress, detects stalls, computes disengagement scores (balancing sunk cost, opportunity cost, and progress), and recommends when to disengage.

Six disengagement reasons are modeled: sunk cost, low progress, opportunity cost, goal conflict, resource exhaustion, and external block.

## Usage

```ruby
client = Legion::Extensions::CognitiveDisengagement::Client.new

goal = client.create_disengagement_goal(
  label: 'optimize inference latency to under 100ms',
  domain: :performance
)

client.check_goal_progress(goal_id: goal[:goal][:id], new_progress: 0.1, effort: 0.3)
client.check_goal_progress(goal_id: goal[:goal][:id], new_progress: 0.11, effort: 0.3)

assessment = client.assess_goal_disengagement(goal_id: goal[:goal][:id])
# => { should_disengage: true, score: 0.72, reason: :low_progress }

client.disengage_from_goal(goal_id: goal[:goal][:id], reason: :low_progress)
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
