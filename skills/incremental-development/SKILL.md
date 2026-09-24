---
name: incremental-development
description: Implements functionality in any language as a sequence of small, approved tasks. Each task changes at most 4 files and includes its unit test, which is written first and approved before the implementation. Constants and models come first and logic last. The code adds debug and info logs and metrics following the project's conventions, and it follows clean code rules (small methods, at most 3 indentation levels, boolean checks extracted into methods). Use when the user asks to implement, build, add or develop a feature or functionality.
---

# Incremental Development

Features are built in small tasks that the user can review and commit one at a time. **You never move forward without the user's approval.**

```
Plan ──approve──▶ Task 1: test ──approve──▶ Task 1: code ──review + commit──▶ Task 2: test ──▶ ...
```

## 1. Plan (no code)

1. Understand the request. Read the code the feature touches and the project's conventions. Ask about anything that changes the design; don't guess. Also find how the project does logging and metrics (see [Logs and metrics](#4-logs-and-metrics)).
2. Break the feature into tasks. Each task:
   - **creates or changes at most 4 files, counting its test file,**
   - delivers one small, coherent piece of the feature that can be reviewed and committed on its own,
   - leaves the build compiling and the existing tests passing once its implementation is done.
3. **Order the tasks from the foundation up to the logic:**
   1. Constants, enums, configuration keys, error codes and messages, and metric names and tags
   2. Models: DTOs, entities, value objects, events, requests and responses
   3. Interfaces and contracts: ports, repository and client interfaces
   4. Logic: services, use cases, validators and mappers, one piece per task
   5. Wiring: controllers, handlers, consumers, dependency configuration
4. **Every task includes a unit test file.** The only exception is a task that only declares data with no behavior (plain constants, or a model with no validation, factory methods or computed values), where a test would only test the language. Mark these tasks as "no test" in the plan so the user can agree or ask for one.
5. Present the plan and **stop**. For each task, show its goal, the files it creates or changes (at most 4), the test it includes, and the logs and metrics it adds. See [references/examples.md](references/examples.md#plan).

Don't write any code until the user approves the plan. If the user changes the plan, update it and present it again.

## 2. For each task: test first

Work on **one task at a time**, in plan order.

### 2a. Write the test

1. Write the unit test for the task's behavior **before** any production code. Cover success and failure scenarios.
2. Production code the test needs may not exist yet, so a test that doesn't compile is acceptable. Don't create production code to make it compile.
3. If a language-specific test skill is available (e.g. `java-unit-tests` for Java), follow it for this phase. Its review stops count as the test approval.
4. **Stop.** Show the scenarios the test covers, and ask the user to approve the test.

### 2b. Implement

1. Only after the test is approved, write the production code for this task.
2. Don't change the approved test to make it pass. If the test seems wrong, stop and explain why.
3. Stay within the task's files. If you need a file that isn't in the plan, or the task would go over 4 files, stop and propose splitting the task or updating the plan.
4. Run the task's test and the related existing tests if you can, and report the results.
5. **Stop.** Summarize what changed, file by file, and ask the user to review and commit.

### 2c. Next task

Start the next task only when the user says so, which is normally after they've committed. Show the plan with each task's status when you start a task, so progress is always visible:

```
✅ 1. Order status enum and error messages
✅ 2. Order and OrderItem models
▶️ 3. Order total calculation   ← test written, waiting for approval
⬜ 4. Order creation service
```

**Never commit, push or create branches yourself.** The user reviews and commits each task.

## 3. Clean code rules

These rules apply to all production code and test code you write or change.

### Hard rules

- **Small, specialized methods.** Each method does one thing, and its name says what that is. If you'd describe it with "and", split it.
- **At most 3 indentation levels inside a method body.** The method body is level 1, and each nested block (`if`, loop, `try`, `switch` case, lambda or closure body) adds a level. When code would reach level 4, reduce nesting with guard clauses and early returns, or extract a method.
- **Boolean checks go in methods.** Any condition that combines more than one operand or expresses a rule becomes a well-named method, e.g. `if (isEligibleForFreeShipping(order))` rather than `if (order.total() > 100 && !order.isInternational())`. Conditions that are already a single named check (`if (customer.isActive())`, `if (items.isEmpty())`) stay as they are.

See [references/examples.md](references/examples.md#clean-code) for examples.

### Also

- **Intention-revealing names:** no abbreviations, single letters or generic names (`data`, `info`, `manager`), except for conventional loop indexes.
- **No magic values:** numbers and strings with meaning become the constants created in the foundation tasks.
- **Few parameters:** more than 3 usually means a missing model object.
- **No duplication:** extract repeated logic.
- **No comments that explain what the code does.** Rename or extract instead. Comments explain *why*, and documentation comments follow the project's rules.
- **Follow the project's conventions,** formatter and linter where they don't conflict with the hard rules above.

## 4. Logs and metrics

Whenever possible, logic and wiring code adds **debug and info logs** and **metrics**, following the way the project already does them.

### Follow the project

Before planning, find out how the project does it:

- **Libraries:** the logger (SLF4J/Logback, Log4j, `logging`, winston, pino, zap, …) and metrics library (Micrometer, Prometheus client, OpenTelemetry, StatsD, …) already in use.
- **Structure:** how loggers are declared, whether logs are structured (key-value, MDC, JSON), where metric names are defined (a constants class, a dedicated metrics class per feature), and the naming conventions for metrics and tags.
- Reuse existing metric names and tags where they fit, and follow the same patterns for new ones.

If the project has no logging or metrics library, **don't add one on your own.** Say so in the plan and ask.

### Logs

- **info:** business events and outcomes, once per operation, e.g. `Order created orderId={} customerId={} items={}`. These are what someone reads to know what the system did.
- **debug:** the details behind a decision: inputs, the branch taken and why, calls to external systems and their results, e.g. `Customer is blocked, rejecting order customerId={}`.
- Use the logger's parameterized or structured form, not string concatenation.
- Log ids and a few relevant fields, **never whole objects or sensitive data**: passwords, tokens, secrets, card numbers, personal data such as emails, documents and addresses.
- Don't log in tight loops, and don't log the same event at several layers.

### Metrics

- **Counters** for business events and their outcomes, e.g. orders created, and orders rejected tagged by `reason`.
- **Timers** for main operations and calls to external systems (database, queues, HTTP).
- **Gauges** only for current state, such as a queue size.
- **Tags must have low cardinality:** status, reason or type. Never ids, emails or free text.
- Metric names and tag keys are constants, created in the constants task.
- If recording metrics makes a method long or noisy, move it to a feature metrics class (e.g. `OrderMetrics`), following the project's structure. That class counts toward the task's 4 files.

### Tests

- Test metrics that record business outcomes when the library supports it (e.g. a `SimpleMeterRegistry`, or a mocked metrics class), and when the project already tests metrics.
- Don't assert on log output.

## Checklist before stopping at 2b

- [ ] Only the task's files were created or changed, at most 4, including the test
- [ ] The approved test wasn't changed to make it pass
- [ ] No method goes deeper than 3 indentation levels
- [ ] Methods are small and do one thing, and compound or rule conditions are extracted into boolean methods
- [ ] No magic values. Constants from earlier tasks are used
- [ ] Info logs for business outcomes, debug logs for decisions and external calls, following the project's logging style, with no sensitive data
- [ ] Metrics follow the project's library and naming, and tags have low cardinality
- [ ] Tests were run (or you explained why they couldn't be), and results are reported
- [ ] Nothing was committed, and the user was asked to review and commit
