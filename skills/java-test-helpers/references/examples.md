# Examples

## Production types

```java
package com.example.customer;

public record CustomerDTO(
        Long id,
        @NotBlank @Size(max = 100) String name,
        @Email String email,
        @Past LocalDate birthDate,
        CustomerStatus status,
        AddressDTO address,
        List<String> tags) {
}

public enum CustomerStatus { ACTIVE, DISABLED, PENDING }

public record AddressDTO(String street, String city, @Pattern(regexp = "\\d{5}") String zipCode) {
}
```

## Helper

```java
package com.example.customer;

import java.time.LocalDate;
import java.util.List;

import static com.example.RandomData.randomEmail;
import static com.example.RandomData.randomId;
import static com.example.RandomData.randomPastDate;
import static com.example.RandomData.randomString;
import static com.example.customer.AddressHelper.anAddress;

/**
 * Test data helper for {@link CustomerDTO}.
 */
public final class CustomerHelper {

    private CustomerHelper() {
    }

    /**
     * Creates a builder for a complete, valid {@link CustomerDTO}.
     * Every property is random except the status, which is {@link CustomerStatus#ACTIVE}.
     * Each call returns a builder with new random values.
     *
     * @return a new customer builder
     */
    public static CustomerBuilder aCustomer() {
        return new CustomerBuilder();
    }

    /**
     * Builder for {@link CustomerDTO} test data. Create it with {@link CustomerHelper#aCustomer()}.
     */
    public static final class CustomerBuilder {

        private Long id = randomId();
        private String name = randomString(20);
        private String email = randomEmail();
        private LocalDate birthDate = randomPastDate();
        private CustomerStatus status = CustomerStatus.ACTIVE;   // preferred default, not random
        private AddressDTO address = anAddress().build();
        private List<String> tags = List.of(randomString(10));

        private CustomerBuilder() {
        }

        /**
         * Sets the customer id. Defaults to a random positive id.
         *
         * @param id the customer id
         * @return this builder
         */
        public CustomerBuilder withId(Long id) {
            this.id = id;
            return this;
        }

        /**
         * Sets the customer name. Defaults to a random 20-letter string.
         *
         * @param name the customer name
         * @return this builder
         */
        public CustomerBuilder withName(String name) {
            this.name = name;
            return this;
        }

        /**
         * Sets the customer email. Defaults to a random valid email.
         *
         * @param email the customer email
         * @return this builder
         */
        public CustomerBuilder withEmail(String email) {
            this.email = email;
            return this;
        }

        /**
         * Sets the customer birth date. Defaults to a random date in the past.
         *
         * @param birthDate the customer birth date
         * @return this builder
         */
        public CustomerBuilder withBirthDate(LocalDate birthDate) {
            this.birthDate = birthDate;
            return this;
        }

        /**
         * Sets the customer status. Defaults to {@link CustomerStatus#ACTIVE}.
         *
         * @param status the customer status
         * @return this builder
         */
        public CustomerBuilder withStatus(CustomerStatus status) {
            this.status = status;
            return this;
        }

        /**
         * Sets the customer address. Defaults to a random address from {@link AddressHelper#anAddress()}.
         *
         * @param address the customer address
         * @return this builder
         */
        public CustomerBuilder withAddress(AddressDTO address) {
            this.address = address;
            return this;
        }

        /**
         * Sets the customer tags. Defaults to a list with one random tag.
         *
         * @param tags the customer tags
         * @return this builder
         */
        public CustomerBuilder withTags(List<String> tags) {
            this.tags = tags;
            return this;
        }

        /**
         * Builds a new {@link CustomerDTO} with the current values.
         *
         * @return a new customer
         */
        public CustomerDTO build() {
            return new CustomerDTO(id, name, email, birthDate, status, address, tags);
        }
    }
}
```

```java
package com.example.customer;

import static com.example.RandomData.randomDigits;
import static com.example.RandomData.randomString;

/**
 * Test data helper for {@link AddressDTO}.
 */
public final class AddressHelper {

    private AddressHelper() {
    }

    /**
     * Creates a builder for a complete, valid {@link AddressDTO} with random values.
     * The zip code matches the {@code \d{5}} pattern.
     * Each call returns a builder with new random values.
     *
     * @return a new address builder
     */
    public static AddressBuilder anAddress() {
        return new AddressBuilder();
    }

    /**
     * Builder for {@link AddressDTO} test data. Create it with {@link AddressHelper#anAddress()}.
     */
    public static final class AddressBuilder {

        private String street = randomString(30);
        private String city = randomString(15);
        private String zipCode = randomDigits(5);   // must match @Pattern("\\d{5}")

        private AddressBuilder() {
        }

        /**
         * Sets the street. Defaults to a random 30-letter string.
         *
         * @param street the street
         * @return this builder
         */
        public AddressBuilder withStreet(String street) {
            this.street = street;
            return this;
        }

        /**
         * Sets the city. Defaults to a random 15-letter string.
         *
         * @param city the city
         * @return this builder
         */
        public AddressBuilder withCity(String city) {
            this.city = city;
            return this;
        }

        /**
         * Sets the zip code. Defaults to 5 random digits.
         *
         * @param zipCode the zip code
         * @return this builder
         */
        public AddressBuilder withZipCode(String zipCode) {
            this.zipCode = zipCode;
            return this;
        }

        /**
         * Builds a new {@link AddressDTO} with the current values.
         *
         * @return a new address
         */
        public AddressDTO build() {
            return new AddressDTO(street, city, zipCode);
        }
    }
}
```

The example notes:

- Every class and non-private method has Javadoc. Each `with...()` method states its default, so a test author can see what they get without setting it.
- `aCustomer()` uses `a` because "customer" starts with a consonant sound, and `anAddress()` uses `an` because "address" starts with a vowel sound.
- The field initializers run when `aCustomer()` creates the builder, so each call gets new random values.
- `status` is `ACTIVE`, the happy path. A test for disabled customers says so explicitly with `withStatus(DISABLED)`.
- `name` has 20 characters, which fits `@Size(max = 100)`. `zipCode` matches the `@Pattern`. The birth date is in the past, as `@Past` requires.
- `address` comes from `AddressHelper`. The customer helper doesn't build addresses itself.

## RandomData

Created once in the project's base test package (`src/test/java/com/example/RandomData.java`). Methods are added as helpers need them.

```java
package com.example;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Random values for test data. Test helpers use it to fill builders with values
 * that don't matter to a scenario.
 */
public final class RandomData {

    private static final String LETTERS = "abcdefghijklmnopqrstuvwxyz";

    private RandomData() {
    }

    /**
     * Returns a random positive id.
     *
     * @return a random value between 1 and {@link Long#MAX_VALUE}
     */
    public static long randomId() {
        return random().nextLong(1, Long.MAX_VALUE);
    }

    /**
     * Returns a random UUID.
     *
     * @return a random UUID
     */
    public static UUID randomUuid() {
        return UUID.randomUUID();
    }

    /**
     * Returns a random 12-letter lowercase string.
     *
     * @return a random string
     */
    public static String randomString() {
        return randomString(12);
    }

    /**
     * Returns a random lowercase string.
     *
     * @param length the number of letters
     * @return a random string of the given length
     */
    public static String randomString(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(LETTERS.charAt(random().nextInt(LETTERS.length())));
        }
        return sb.toString();
    }

    /**
     * Returns a random string of digits, e.g. for zip codes or document numbers.
     *
     * @param length the number of digits
     * @return a random digit string of the given length
     */
    public static String randomDigits(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(random().nextInt(10));
        }
        return sb.toString();
    }

    /**
     * Returns a random, syntactically valid email address.
     *
     * @return a random email
     */
    public static String randomEmail() {
        return randomString(10) + "@" + randomString(8) + ".com";
    }

    /**
     * Returns a random int in a range.
     *
     * @param minInclusive the lowest possible value
     * @param maxExclusive the upper bound, not included
     * @return a random int in the range
     */
    public static int randomInt(int minInclusive, int maxExclusive) {
        return random().nextInt(minInclusive, maxExclusive);
    }

    /**
     * Returns a random decimal in a range, e.g. for amounts.
     *
     * @param minInclusive the lowest possible value
     * @param maxExclusive the upper bound, not included
     * @param scale the number of decimal places
     * @return a random decimal in the range
     */
    public static BigDecimal randomBigDecimal(double minInclusive, double maxExclusive, int scale) {
        return BigDecimal.valueOf(random().nextDouble(minInclusive, maxExclusive))
                .setScale(scale, RoundingMode.HALF_UP);
    }

    /**
     * Returns a random date between 1 day and about 100 years ago.
     *
     * @return a random past date
     */
    public static LocalDate randomPastDate() {
        return LocalDate.now().minusDays(randomInt(1, 36_500));
    }

    /**
     * Returns a random date between 1 day and about 100 years from today.
     *
     * @return a random future date
     */
    public static LocalDate randomFutureDate() {
        return LocalDate.now().plusDays(randomInt(1, 36_500));
    }

    /**
     * Returns a random constant of an enum. Use it only for enums that don't affect behavior.
     *
     * @param type the enum class
     * @param <E> the enum type
     * @return a random constant of the enum
     */
    public static <E extends Enum<E>> E randomEnum(Class<E> type) {
        E[] values = type.getEnumConstants();
        return values[random().nextInt(values.length)];
    }

    private static ThreadLocalRandom random() {
        return ThreadLocalRandom.current();
    }
}
```

`randomEnum` is for enums whose value never affects behavior (e.g. a display color). Enums that the logic depends on use a preferred default in the builder.

## Using helpers in a test

```java
@Test
void shouldRejectOrderWhenCustomerIsDisabled() {
    // given
    CustomerDTO customer = aCustomer().withStatus(DISABLED).build();
    when(customerClient.findById(customer.id())).thenReturn(customer);

    // when / then
    assertThatThrownBy(() -> sut.createOrder(customer.id(), anOrderRequest().build()))
            .isInstanceOf(BusinessException.class)
            .hasMessage("Customer " + customer.id() + " is disabled");
}
```

Only the status that matters to the scenario is set. The id, name, address and the order request are random, and the assertion uses `customer.id()` rather than a literal.
