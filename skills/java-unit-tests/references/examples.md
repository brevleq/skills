# Examples

All examples test this class:

```java
public class OrderService {

    private final CustomerRepository customerRepository;
    private final OrderRepository orderRepository;
    private final OrderEventPublisher eventPublisher; // publishes to a Kafka topic

    public OrderService(CustomerRepository customerRepository,
                        OrderRepository orderRepository,
                        OrderEventPublisher eventPublisher) {
        this.customerRepository = customerRepository;
        this.orderRepository = orderRepository;
        this.eventPublisher = eventPublisher;
    }

    public Order createOrder(CreateOrderRequest request) {
        if (request.items() == null || request.items().isEmpty()) {
            throw new IllegalArgumentException("Order must have at least one item");
        }
        Customer customer = customerRepository.findById(request.customerId())
                .orElseThrow(() -> new CustomerNotFoundException(request.customerId()));
        if (customer.isBlocked()) {
            throw new BusinessException("Customer " + customer.id() + " is blocked");
        }
        Order saved = orderRepository.save(Order.from(customer, request.items()));
        eventPublisher.publish(new OrderCreatedEvent(saved.id()));
        return saved;
    }
}
```

## Step 1

Only method names and `fail()`. No fields, mocks or setup.

```java
package com.example.order;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.fail;

class OrderServiceTest {

    @Nested
    class CreateOrder {

        // success
        @Test
        void shouldSaveOrderWhenRequestIsValid() {
            fail("Not implemented yet");
        }

        @Test
        void shouldPublishOrderCreatedEventWhenOrderIsSaved() {
            fail("Not implemented yet");
        }

        // failure
        @Test
        void shouldThrowIllegalArgumentExceptionWhenItemsAreNull() {
            fail("Not implemented yet");
        }

        @Test
        void shouldThrowIllegalArgumentExceptionWhenItemsAreEmpty() {
            fail("Not implemented yet");
        }

        @Test
        void shouldThrowCustomerNotFoundExceptionWhenCustomerDoesNotExist() {
            fail("Not implemented yet");
        }

        @Test
        void shouldThrowBusinessExceptionWhenCustomerIsBlocked() {
            fail("Not implemented yet");
        }

        @Test
        void shouldNotPublishEventWhenSavingOrderFails() {
            fail("Not implemented yet");
        }
    }
}
```

Reply to the developer after step 1:

> I created 7 test skeletons in `OrderServiceTest` for `createOrder`:
>
> **Success:** the order is saved; an `OrderCreatedEvent` is published after the save.
> **Failure:** items are null; items are empty; the customer doesn't exist; the customer is blocked; the event isn't published when the save fails.
>
> I didn't add a test for a `null` request: the method would throw a `NullPointerException`, and I'm not sure that's the intended behavior.
>
> Please review, delete or add scenarios, and tell me when to implement them.

## Step 3

Say the developer deleted `shouldThrowIllegalArgumentExceptionWhenItemsAreNull` during review. The remaining tests are implemented, and no new ones are added.

```java
package com.example.order;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static com.example.test.CustomerFixtures.activeCustomer;
import static com.example.test.RandomData.randomId;
import static com.example.test.RandomData.randomQuantity;
import static com.example.test.RandomData.randomString;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    // random values: none of these tests depends on a specific id, SKU or quantity
    private final long customerId = randomId();
    private final List<Item> items = List.of(new Item(randomString(), randomQuantity()));

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private OrderEventPublisher eventPublisher;

    @InjectMocks
    private OrderService sut;

    @Nested
    class CreateOrder {

        // success
        @Test
        void shouldSaveOrderWhenRequestIsValid() {
            // given
            Customer customer = activeCustomer(customerId);
            when(customerRepository.findById(customerId)).thenReturn(Optional.of(customer));
            when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

            // when
            Order result = sut.createOrder(new CreateOrderRequest(customerId, items));

            // then
            ArgumentCaptor<Order> captor = ArgumentCaptor.forClass(Order.class);
            verify(orderRepository).save(captor.capture());
            assertThat(captor.getValue().customer()).isEqualTo(customer);
            assertThat(captor.getValue().items()).containsExactlyElementsOf(items);
            assertThat(result).isSameAs(captor.getValue());
        }

        @Test
        void shouldPublishOrderCreatedEventWhenOrderIsSaved() {
            // given
            long orderId = randomId();
            Order saved = new Order(orderId, activeCustomer(customerId), items);
            when(customerRepository.findById(customerId)).thenReturn(Optional.of(activeCustomer(customerId)));
            when(orderRepository.save(any(Order.class))).thenReturn(saved);

            // when
            sut.createOrder(new CreateOrderRequest(customerId, items));

            // then
            verify(eventPublisher).publish(new OrderCreatedEvent(orderId));
        }

        // failure
        @Test
        void shouldThrowIllegalArgumentExceptionWhenItemsAreEmpty() {
            // given
            // fixed value: an empty list is the scenario
            CreateOrderRequest request = new CreateOrderRequest(customerId, List.of());

            // when / then
            assertThatThrownBy(() -> sut.createOrder(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessage("Order must have at least one item");
            verifyNoInteractions(customerRepository, orderRepository, eventPublisher);
        }

        @Test
        void shouldThrowCustomerNotFoundExceptionWhenCustomerDoesNotExist() {
            // given
            when(customerRepository.findById(customerId)).thenReturn(Optional.empty());

            // when / then
            assertThatThrownBy(() -> sut.createOrder(new CreateOrderRequest(customerId, items)))
                    .isInstanceOf(CustomerNotFoundException.class);
            verifyNoInteractions(orderRepository, eventPublisher);
        }

        @Test
        void shouldThrowBusinessExceptionWhenCustomerIsBlocked() {
            // given
            when(customerRepository.findById(customerId))
                    // fixed value: blocked = true is the scenario
                    .thenReturn(Optional.of(new Customer(customerId, true)));

            // when / then
            assertThatThrownBy(() -> sut.createOrder(new CreateOrderRequest(customerId, items)))
                    .isInstanceOf(BusinessException.class)
                    .hasMessage("Customer " + customerId + " is blocked");
            verifyNoInteractions(orderRepository, eventPublisher);
        }

        @Test
        void shouldNotPublishEventWhenSavingOrderFails() {
            // given
            when(customerRepository.findById(customerId)).thenReturn(Optional.of(activeCustomer(customerId)));
            String errorMessage = randomString();
            when(orderRepository.save(any(Order.class))).thenThrow(new RuntimeException(errorMessage));

            // when / then
            assertThatThrownBy(() -> sut.createOrder(new CreateOrderRequest(customerId, items)))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessage(errorMessage);
            verify(eventPublisher, never()).publish(any());
        }
    }
}
```

The example notes:

- Every dependency (`CustomerRepository`, `OrderRepository`, `OrderEventPublisher`) is a `@Mock`. No database or Kafka is involved.
- `Customer`, `Order`, `Item` and the request are real objects, not mocks.
- The failure tests verify that nothing was saved or published.
- There are no private helper methods. Random values come from the `RandomData` helper class, and the active customer comes from `CustomerFixtures`. Both are helper classes that already exist in the project, or that were created with the `java-test-helpers` skill. The names here are only illustrative.
- Ids, the SKU, the quantity and the error message are random, and assertions use the same variables. So an implementation that hard codes a customer id or an event id fails. The empty item list and `blocked = true` stay fixed because they are the scenarios.
- The `// when / then` form is used only when the call and the exception assertion are one statement (`assertThatThrownBy`).

## Test first: reply for a new feature

If `OrderService.createOrder` didn't exist yet, the step 3 test code would be the same. The reply lists the API the tests expect, and it doesn't create any of that code:

> I implemented the 6 tests in `OrderServiceTest`. The test sources don't compile yet because the feature code doesn't exist. That's expected, and it also means the other tests in this module can't run until the code is added.
>
> **API the tests expect:**
> - `OrderService(CustomerRepository, OrderRepository, OrderEventPublisher)`
> - `Order OrderService.createOrder(CreateOrderRequest request)`
> - `record CreateOrderRequest(long customerId, List<Item> items)`
> - `record OrderCreatedEvent(long orderId)`
> - `void OrderEventPublisher.publish(OrderCreatedEvent event)`
> - `BusinessException` with the message `"Customer <id> is blocked"`
>
> Every compilation error comes from these missing types. `CustomerRepository`, `Customer` and `CustomerNotFoundException` already exist and are used as they are.
