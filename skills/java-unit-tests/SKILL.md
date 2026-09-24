---
name: java-unit-tests
description: Creates Java unit tests with JUnit 5, Mockito and AssertJ in a two-phase, developer-reviewed workflow. Phase 1 lists every success and failure scenario as empty test methods that only call fail(). Phase 2 implements those tests after the developer has reviewed them. Use when asked to write, create, add or implement unit tests for a Java class, method or feature.
---

# Java Unit Tests

Unit tests are written in four steps. Two of them are done by you and two by a developer:

| Step | Who | What |
|------|-----|------|
| 1 | You | Identify all scenarios and create **empty** test methods that only call `fail()` |
| 2 | Developer | Reviews the scenarios; may delete, rename or add test methods |
| 3 | You | Implement the test methods that are in the file now. **Test code only** |
| 4 | Developer | Reviews and adjusts the implemented tests |

**Stop after step 1 and after step 3.** Never do step 1 and step 3 in the same turn, even if asked to "write tests". The developer's review in between is the point of this workflow.

## Which step am I on?

- The test class doesn't exist yet, or has no tests for the feature → **step 1**.
- The test class has methods whose body is only `fail("Not implemented yet")`, and the developer says the review is done / asks to implement → **step 3**.
- If it's unclear, ask.

## Stack

- **JUnit 5** (`org.junit.jupiter`), **Mockito** (`mockito-junit-jupiter`), **AssertJ**.
- Before writing anything, check the build file (`pom.xml` / `build.gradle(.kts)`) for these dependencies. If one is missing, tell the developer which to add. Don't edit the build file without asking.
- Follow the conventions of existing tests in the project (naming, `@Nested`, `@DisplayName`, fixture builders) where they don't conflict with this skill.

## Step 1: failing test skeletons

1. Read the class under test and everything it depends on: constructor dependencies, the methods it calls on them, the exceptions it throws, and the validation it does.
2. List the scenarios for each public method of the feature:
   - **Success:** the happy path, plus each meaningfully different successful branch (e.g. existing vs. new entity, optional field present vs. absent).
   - **Invalid input:** `null`, empty, blank, out of range, boundary values, invalid state.
   - **Business rule violations:** each rule that rejects the request.
   - **Dependency failures:** each dependency that can fail (repository throws, endpoint returns an error or times out, queue publish fails, entity not found).
   - **Side effects:** what must be saved, published or sent, and what must **not** happen when something fails (e.g. no message published when the save fails).
3. Create the test class in `src/test/java`, in the same package as the class under test, named `<ClassName>Test`. If it already exists, add to it and don't touch the existing tests.
4. Each scenario is one test method whose body is **only** `fail("Not implemented yet");`. No setup, no mocks, no fields, no given/when/then code.
5. Name methods `should<ExpectedResult>When<Condition>`, e.g. `shouldThrowNotFoundExceptionWhenCustomerDoesNotExist`. The name alone must make the scenario clear to the reviewer.
6. Group the tests by method under test with `@Nested` classes when the class has more than one public method under test.
7. **Stop.** Reply with a short list of the scenarios, grouped by success / failure, and ask the developer to review them. Mention any scenario you left out on purpose, and any behavior that looked ambiguous in the code.

See [references/examples.md](references/examples.md#step-1) for a full example.

## Step 3: implement the test cases

1. **Re-read the test class first.** The developer may have deleted, renamed or added methods. The file is the source of truth, not your step 1 output.
2. Implement exactly the test methods in the file. Don't add, remove or rename tests. If you think a scenario is missing, say so in your reply and don't add it.
3. **Change test code only.** Don't modify production code, build files or other tests. If a test can't be written without changing production code (e.g. a dependency created with `new` inside the class, static calls, hidden time or randomness), write what you can, leave that test failing with a `fail("...")` that explains the problem, and report it.
4. Structure each test as `// given`, `// when`, `// then`.
5. Run the test class if you can (`mvn -Dtest=<ClassName>Test test` or `gradle test --tests <ClassName>Test`) and report the results. A test that fails because the feature isn't implemented yet is a valid result, so report it and don't "fix" it.
6. Go through the checklist below, then **stop** and ask the developer to review.

See [references/examples.md](references/examples.md#step-3) for a full example.

## Rules for implemented tests

### Mock all external communication

The class under test is the only real object with behavior. **Everything that talks to the outside world is a Mockito mock**, including:

- Databases: repositories, DAOs, `EntityManager`, `JdbcTemplate`, MongoDB/Redis clients
- Messaging: `KafkaTemplate`, `JmsTemplate`, `RabbitTemplate`, SQS/SNS/PubSub clients, event publishers
- HTTP and RPC: `RestTemplate`, `WebClient`, `RestClient`, Feign clients, gRPC stubs, SDK clients (AWS, GCP, etc.)
- Files and storage: file system access, S3/blob storage
- Non-determinism: `Clock` (use `Clock.fixed(...)` or a mock), UUID or random generators, when they're injected
- Other services or components of your own that the class depends on

Never use `@SpringBootTest`, `@DataJpaTest`, `@WebMvcTest`, Testcontainers, embedded databases or brokers, WireMock or a real network in these tests. Those are integration tests, not unit tests.

Don't mock value objects, DTOs, entities or collections. Build real instances of them.

### Mockito

- `@ExtendWith(MockitoExtension.class)` with `@Mock` for dependencies and `@InjectMocks` for the class under test (or construct it by hand in `@BeforeEach` if there's more than one constructor).
- The field holding the class under test is always named **`sut`** (system under test), e.g. `@InjectMocks private OrderService sut;`, so it stands out from the mocks.
- Keep Mockito's strict stubbing. Stub only what the test needs, and don't use `lenient()` to hide unused stubs.
- Prefer argument values or `ArgumentCaptor` over `any()` when the argument matters to the scenario.
- Use `verify(...)` for side effects that are the point of the test (saved, published, sent), and `verify(mock, never())` / `verifyNoInteractions(mock)` for things that must not happen in failure scenarios.
- Don't verify calls whose result is already asserted, e.g. a stubbed `findById` used to compute the return value.

### AssertJ

- Use **only** AssertJ for assertions: `assertThat(...)`, `assertThatThrownBy(...)`, `assertThatExceptionOfType(...)`, `assertThatCode(...).doesNotThrowAnyException()`. No JUnit `assertEquals` / `assertThrows` / `assertTrue`.
- For exceptions, assert the type **and** the message or relevant fields.
- Compare objects with `usingRecursiveComparison()` or `extracting(...)` rather than asserting every field one by one.

### General

- One scenario per test. The `// when` section has a single call to the class under test.
- Tests are independent. There's no shared mutable state and no order dependency.
- No `Thread.sleep`, and no logic (`if`, loops) in tests.
- Test data should be minimal and meaningful. Use constants or small factory methods when the same data repeats.

## Checklist before stopping in step 3

- [ ] Every test method that was in the file after the developer's review is implemented, and none were added, removed or renamed
- [ ] No production code or build files were changed
- [ ] Every external dependency is a `@Mock`, and there's no Spring context, database, broker or network
- [ ] The class under test is in a field named `sut`
- [ ] All assertions use AssertJ
- [ ] Failure scenarios verify that side effects did **not** happen
- [ ] No unnecessary stubbing, and the tests pass Mockito strict stubs
- [ ] Test results (or why they couldn't be run) are reported to the developer
