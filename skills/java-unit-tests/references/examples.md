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

Only Javadoc, method names and `fail()`. No fields, mocks or setup. The Javadoc describes each scenario so the developer can review it.

```java
package com.example.order;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.fail;

/**
 * Unit tests for {@link OrderService}.
 */
class OrderServiceTest {

    /**
     * Tests for {@link OrderService#createOrder(CreateOrderRequest)}.
     */
    @Nested
    class CreateOrder {

        // success
        /**
         * Given an active customer and a request with items,
         * when an order is created,
         * then the order is saved with the customer and the items and returned.
         */
        @Test
        void shouldSaveOrderWhenRequestIsValid() {
            fail("Not implemented yet");
        }

        /**
         * Given a valid request whose order is saved,
         * when an order is created,
         * then an {@link OrderCreatedEvent} with the saved order's id is published.
         */
        @Test
        void shouldPublishOrderCreatedEventWhenOrderIsSaved() {
            fail("Not implemented yet");
        }

        // failure
        /**
         * Given a request with {@code null} items,
         * when an order is created,
         * then an {@link IllegalArgumentException} is thrown and no dependency is called.
         */
        @Test
        void shouldThrowIllegalArgumentExceptionWhenItemsAreNull() {
            fail("Not implemented yet");
        }

        /**
         * Given a request with an empty item list,
         * when an order is created,
         * then an {@link IllegalArgumentException} is thrown and no dependency is called.
         */
        @Test
        void shouldThrowIllegalArgumentExceptionWhenItemsAreEmpty() {
            fail("Not implemented yet");
        }

        /**
         * Given a customer id that doesn't exist,
         * when an order is created,
         * then a {@link CustomerNotFoundException} is thrown and nothing is saved or published.
         */
        @Test
        void shouldThrowCustomerNotFoundExceptionWhenCustomerDoesNotExist() {
            fail("Not implemented yet");
        }

        /**
         * Given a blocked customer,
         * when an order is created,
         * then a {@link BusinessException} is thrown and nothing is saved or published.
         */
        @Test
        void shouldThrowBusinessExceptionWhenCustomerIsBlocked() {
            fail("Not implemented yet");
        }

        /**
         * Given that saving the order fails,
         * when an order is created,
         * then the exception is propagated and no event is published.
         */
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

import static com.example.RandomData.randomId;
import static com.example.RandomData.randomString;
import static com.example.order.CustomerHelper.aCustomer;
import static com.example.order.ItemHelper.anItem;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link OrderService}.
 */
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    // random values: none of these tests depends on a specific id, SKU or quantity
    private final long customerId = randomId();
    private final List<Item> items = List.of(anItem().build());

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private OrderEventPublisher eventPublisher;

    @InjectMocks
    private OrderService sut;

    /**
     * Tests for {@link OrderService#createOrder(CreateOrderRequest)}.
     */
    @Nested
    class CreateOrder {

        // success
        /**
         * Given an active customer and a request with items,
         * when an order is created,
         * then the order is saved with the customer and the items and returned.
         */
        @Test
        void shouldSaveOrderWhenRequestIsValid() {
            // given
            Customer customer = aCustomer().withId(customerId).build();
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

        /**
         * Given a valid request whose order is saved,
         * when an order is created,
         * then an {@link OrderCreatedEvent} with the saved order's id is published.
         */
        @Test
        void shouldPublishOrderCreatedEventWhenOrderIsSaved() {
            // given
            long orderId = randomId();
            Order saved = new Order(orderId, aCustomer().withId(customerId).build(), items);
            when(customerRepository.findById(customerId)).thenReturn(Optional.of(aCustomer().withId(customerId).build()));
            when(orderRepository.save(any(Order.class))).thenReturn(saved);

            // when
            sut.createOrder(new CreateOrderRequest(customerId, items));

            // then
            verify(eventPublisher).publish(new OrderCreatedEvent(orderId));
        }

        // failure
        /**
         * Given a request with an empty item list,
         * when an order is created,
         * then an {@link IllegalArgumentException} is thrown and no dependency is called.
         */
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

        /**
         * Given a customer id that doesn't exist,
         * when an order is created,
         * then a {@link CustomerNotFoundException} is thrown and nothing is saved or published.
         */
        @Test
        void shouldThrowCustomerNotFoundExceptionWhenCustomerDoesNotExist() {
            // given
            when(customerRepository.findById(customerId)).thenReturn(Optional.empty());

            // when / then
            assertThatThrownBy(() -> sut.createOrder(new CreateOrderRequest(customerId, items)))
                    .isInstanceOf(CustomerNotFoundException.class);
            verifyNoInteractions(orderRepository, eventPublisher);
        }

        /**
         * Given a blocked customer,
         * when an order is created,
         * then a {@link BusinessException} is thrown and nothing is saved or published.
         */
        @Test
        void shouldThrowBusinessExceptionWhenCustomerIsBlocked() {
            // given
            when(customerRepository.findById(customerId))
                    // fixed value: blocked = true is the scenario
                    .thenReturn(Optional.of(aCustomer().withId(customerId).withBlocked(true).build()));

            // when / then
            assertThatThrownBy(() -> sut.createOrder(new CreateOrderRequest(customerId, items)))
                    .isInstanceOf(BusinessException.class)
                    .hasMessage("Customer " + customerId + " is blocked");
            verifyNoInteractions(orderRepository, eventPublisher);
        }

        /**
         * Given that saving the order fails,
         * when an order is created,
         * then the exception is propagated and no event is published.
         */
        @Test
        void shouldNotPublishEventWhenSavingOrderFails() {
            // given
            when(customerRepository.findById(customerId)).thenReturn(Optional.of(aCustomer().withId(customerId).build()));
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

- The test class, the `@Nested` class and every test method have Javadoc. Each test's Javadoc describes its scenario as given / when / then.
- Every dependency (`CustomerRepository`, `OrderRepository`, `OrderEventPublisher`) is a `@Mock`. No database or Kafka is involved.
- `Customer`, `Order`, `Item` and the request are real objects, not mocks.
- The failure tests verify that nothing was saved or published.
- There are no private helper methods. Random values come from `RandomData`, and customers and items come from `CustomerHelper` and `ItemHelper`. These helpers were created with the `java-test-helpers` skill. `aCustomer()` defaults to a customer that isn't blocked, so only the blocked test sets `withBlocked(true)`.
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
