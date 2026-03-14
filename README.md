# lex-cognitive-scaffolding

A LegionIO cognitive architecture extension that models skill acquisition using the Zone of Proximal Development (ZPD) framework. Skills are tracked as scaffolds with competence levels and support tiers that adapt automatically based on practice outcomes.

## What It Does

Tracks a set of **scaffolds**, each representing one skill in a domain. Each scaffold has:

- A competence level (0.0 to 1.0)
- A support level (`:full`, `:guided`, `:prompted`, or `:independent`)
- A task history of practice attempts

When a task is attempted, competence updates based on difficulty and outcome. Support fades automatically on success and increases on failure — modeling how external guidance decreases as mastery grows.

## Usage

```ruby
require 'lex-cognitive-scaffolding'

client = Legion::Extensions::CognitiveScaffolding::Client.new

# Create a scaffold for a skill
result = client.create_scaffold(skill_name: 'python_debugging', domain: :programming)
# => { success: true, scaffold: { id: "uuid...", skill_name: "python_debugging", competence: 0.3, support_level: :prompted, current_zone: :zpd, ... } }

scaffold_id = result[:scaffold][:id]

# Attempt a task — success in the ZPD yields full learning gain
client.attempt_scaffolded_task(scaffold_id: scaffold_id, difficulty: 0.45, success: true)
# => { success: true, scaffold: { competence: 0.38, support_level: :independent, ... } }

# Attempt a harder task — failure increases support and reduces competence
client.attempt_scaffolded_task(scaffold_id: scaffold_id, difficulty: 0.9, success: false)
# => { success: true, scaffold: { competence: 0.35, support_level: :prompted, ... } }

# Get a recommended difficulty for the next task
client.recommend_scaffolded_task(scaffold_id: scaffold_id)
# => { success: true, recommendation: { difficulty: 0.575, support_level: :prompted, zone: :zpd } }

# List skills currently in the ZPD
client.zpd_skills
# => { success: true, skills: [...], count: 1 }

# List mastered skills
client.mastered_scaffolded_skills
# => { success: true, skills: [], count: 0 }

# Query by domain
client.domain_scaffolds(domain: :programming)
# => { success: true, domain: :programming, scaffolds: [...], count: 1 }

# Mean competence across all skills
client.overall_scaffolded_competence
# => { success: true, overall_competence: 0.35 }

# Periodic decay tick (for use with a scheduler)
client.update_cognitive_scaffolding
# => { success: true, action: :decay, scaffold_count: 1, overall_competence: 0.34 }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
