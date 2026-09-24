---
name: java-test-helpers
description: Creates and modifies Java test helper classes that build test data with the Test Data Builder pattern. Each helper has a static a<Type>() or an<Type>() method (e.g. aCustomer(), anAddress()) that returns a builder pre-filled with a complete, valid object of random values and preferred defaults, with a with<Property>() method per property and build(). Use when a unit test needs test data objects (DTOs, entities, requests, events) or when the java-unit-tests skill asks for a new helper.
---

# Java Test Helpers

Test helper classes create test data. A test asks only for the values that matter to its scenario, and the helper fills in everything else:

```java
CustomerDTO customer = aCustomer().build();                            // everything random or default
CustomerDTO disabled = aCustomer().withStatus(DISABLED).build();        // only the status is fixed
```

## Before creating anything

1. **Search `src/test` for existing helpers** of the type (`*Helper`, builders, fixtures). If one exists, extend it instead of creating another.
2. **Read the type** the helper builds: its fields, how to construct it (constructor, record, setters, Lombok `@Builder`), and its validation (Bean Validation annotations, checks in the constructor, invariants between fields).
3. **Look at existing helpers** in the project and follow their package, formatting and style where they don't conflict with this skill.

## Helper class structure

One helper class per data type. Given `CustomerDTO`:

| Element | Convention |
|---------|------------|
| Helper class | `CustomerHelper`: the type name without a `DTO` suffix, plus `Helper`. `public final`, with a private constructor |
| Location | `src/test/java`, in the same package as the type it builds |
| Factory method | `public static CustomerBuilder aCustomer()`. The article follows English pronunciation: `a` before a consonant sound (`aCustomer`, `aUser`), `an` before a vowel sound (`anAddress`, `anOrder`, `anItem`) |
| Builder | `public static final class CustomerBuilder`, nested inside the helper |
| Setters | One `with<Property>(value)` per property, which returns `this` |
| Result | `build()` returns a **new** instance on every call |

If removing the `DTO` suffix would clash with another type's helper (e.g. there's also a `Customer` entity), keep the distinguishing suffix on the other one: `CustomerEntityHelper.aCustomerEntity()`.

Helpers contain only data building. No assertions, no mocks, no calls to production services or repositories, and no state shared between builders.

## Default values

`a<Type>()` / `an<Type>()` returns a builder whose fields are **already set**. Calling `build()` without any `with...()` must produce a **complete and valid** object.

- **Fill every property**, including optional and nullable ones. A test that needs `null` or an empty value sets it explicitly (`withEmail(null)`).
- **Random values** for data whose specific value doesn't matter: ids, names, codes, emails, amounts, quantities, dates, descriptions. This catches implementations that hard code values. Generate them when `an<Type>()` is called, so every builder gets fresh values.
- **Preferred defaults** for values that change behavior: enums and booleans get the "normal", happy-path value (e.g. `status = ACTIVE`, `blocked = false`), not a random one. A random enum could quietly switch a test to a different scenario.
- **Valid for the domain:** random values must pass the type's validation: `@Email`, `@Size`, `@Pattern`, `@Positive`, `@Past`, and so on. They must also keep invariants between fields (`startDate` before `endDate`, `total` equals the sum of the items).
- **Nested objects** use their own helper: `address = anAddress().build()`. Create that helper too if it doesn't exist.
- **Collections** get one element built with the element's helper, unless the type requires more.

## Random values

All random generation goes through one shared class, `RandomData`, in the project's base test package. Helpers and tests never call `ThreadLocalRandom` or `UUID` directly.

- Reuse `RandomData` if it exists, and add methods to it as needed. If it doesn't exist, create it (see [references/examples.md](references/examples.md#randomdata)).
- Keep the methods generic and domain free: `randomId()`, `randomString()`, `randomEmail()`, `randomInt(min, max)`, `randomBigDecimal(...)`, `randomPastDate()`, `randomEnum(type)`. Domain-specific values (a valid tax id, a SKU format) belong in the helper of the type that uses them.
- If the project already has a data library (Datafaker, Instancio, EasyRandom), implement `RandomData` with it. Don't add a new library without asking.

## Building the object

- Build it the way the production type allows: canonical constructor for records, all-args constructor, setters, or the type's own builder (e.g. Lombok's `CustomerDTO.builder()`) inside `build()`.
- **Never change the production type** to make it easier to build (no added setters, constructors or `@Builder`). If it can't be built from a test, tell the developer.
- **Test first:** if the type doesn't exist yet because the feature isn't implemented, write the helper against the type the feature *should* have. Compilation failing because only production code is missing is acceptable. Don't create the production type.

## Javadoc

Every class and method that isn't `private` has Javadoc: the helper class, the `a<Type>()` / `an<Type>()` factory method, the builder class, every `with...()` method, `build()`, and every `RandomData` method. Add it when you create the element, and update it whenever you change it.

- **Helper class:** `Test data helper for {@link CustomerDTO}.`
- **Factory method:** what it builds, which values are random, and which preferred defaults it uses (e.g. `status` is `ACTIVE`). Plus `@return`.
- **Builder class:** what it builds and how to create it.
- **`with...()` methods:** what the property is and **its default value**. Plus `@param` and `@return`.
- **`build()`:** that it returns a new instance. Plus `@return`.
- **`RandomData` methods:** the range or format of the value. Plus `@param` and `@return`.
- When you change a default, update the Javadoc of the factory method and of the `with...()` method in the same change.

## Modifying an existing helper

- **Add** a `with...()` method when a test needs one that's missing.
- **When the type gains a field,** add it to the builder with a random or preferred default, and add its `with...()` method.
- **When the type loses or renames a field,** update the builder to match.
- **Don't change an existing default** (e.g. `ACTIVE` → `PENDING`) without asking the developer. Other tests may rely on it without setting it explicitly.
- Don't remove `with...()` methods that tests still use.
- Add or update the Javadoc of everything you add or change. If existing non-private elements have no Javadoc, add it.

## Checklist

- [ ] One `<Type>Helper` per type, `final`, with a private constructor, in the type's package under `src/test/java`
- [ ] `a<Type>()` / `an<Type>()` (article by pronunciation) returns a builder, and `build()` alone produces a complete, valid object
- [ ] Every property has a `with<Property>()` method that returns the builder
- [ ] Data values are random through `RandomData`, and enums and booleans use happy-path defaults
- [ ] Nested objects and collection elements use their own helpers
- [ ] Every non-private class and method has Javadoc, and each `with...()` method states its default value
- [ ] No production code was changed
- [ ] Existing defaults weren't changed without the developer's approval

See [references/examples.md](references/examples.md) for a complete helper, `RandomData`, and how tests use them.
