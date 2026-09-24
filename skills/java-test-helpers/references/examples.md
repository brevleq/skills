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

public final class CustomerHelper {

    private CustomerHelper() {
    }

    public static CustomerBuilder aCustomer() {
        return new CustomerBuilder();
    }

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

        public CustomerBuilder withId(Long id) {
            this.id = id;
            return this;
        }

        public CustomerBuilder withName(String name) {
            this.name = name;
            return this;
        }

        public CustomerBuilder withEmail(String email) {
            this.email = email;
            return this;
        }

        public CustomerBuilder withBirthDate(LocalDate birthDate) {
            this.birthDate = birthDate;
            return this;
        }

        public CustomerBuilder withStatus(CustomerStatus status) {
            this.status = status;
            return this;
        }

        public CustomerBuilder withAddress(AddressDTO address) {
            this.address = address;
            return this;
        }

        public CustomerBuilder withTags(List<String> tags) {
            this.tags = tags;
            return this;
        }

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

public final class AddressHelper {

    private AddressHelper() {
    }

    public static AddressBuilder anAddress() {
        return new AddressBuilder();
    }

    public static final class AddressBuilder {

        private String street = randomString(30);
        private String city = randomString(15);
        private String zipCode = randomDigits(5);   // must match @Pattern("\\d{5}")

        private AddressBuilder() {
        }

        public AddressBuilder withStreet(String street) {
            this.street = street;
            return this;
        }

        public AddressBuilder withCity(String city) {
            this.city = city;
            return this;
        }

        public AddressBuilder withZipCode(String zipCode) {
            this.zipCode = zipCode;
            return this;
        }

        public AddressDTO build() {
            return new AddressDTO(street, city, zipCode);
        }
    }
}
```

The example notes:

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

public final class RandomData {

    private static final String LETTERS = "abcdefghijklmnopqrstuvwxyz";

    private RandomData() {
    }

    public static long randomId() {
        return random().nextLong(1, Long.MAX_VALUE);
    }

    public static UUID randomUuid() {
        return UUID.randomUUID();
    }

    public static String randomString() {
        return randomString(12);
    }

    public static String randomString(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(LETTERS.charAt(random().nextInt(LETTERS.length())));
        }
        return sb.toString();
    }

    public static String randomDigits(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(random().nextInt(10));
        }
        return sb.toString();
    }

    public static String randomEmail() {
        return randomString(10) + "@" + randomString(8) + ".com";
    }

    public static int randomInt(int minInclusive, int maxExclusive) {
        return random().nextInt(minInclusive, maxExclusive);
    }

    public static BigDecimal randomBigDecimal(double minInclusive, double maxExclusive, int scale) {
        return BigDecimal.valueOf(random().nextDouble(minInclusive, maxExclusive))
                .setScale(scale, RoundingMode.HALF_UP);
    }

    public static LocalDate randomPastDate() {
        return LocalDate.now().minusDays(randomInt(1, 36_500));
    }

    public static LocalDate randomFutureDate() {
        return LocalDate.now().plusDays(randomInt(1, 36_500));
    }

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
