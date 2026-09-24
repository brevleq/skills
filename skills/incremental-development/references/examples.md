# Examples

## Plan

Request: *"Customers can place orders. An order has items, it's rejected if the customer is blocked, shipping is free for domestic orders over 100, and an event is published when the order is created."*

> **Plan: create order (6 tasks)**
>
> **1. Order constants, error messages and metric names**. No test (constants only)
> - `order/OrderStatus.java` (new): `PENDING`, `CONFIRMED`, `CANCELLED`
> - `order/OrderErrors.java` (new): error messages for a blocked customer and an empty order
> - `order/ShippingRules.java` (new): `FREE_SHIPPING_THRESHOLD = 100`
> - `order/OrderMetricNames.java` (new): `orders.created`, `orders.rejected` and the `reason` tag, following the `<domain>.<event>` naming used in `payment/PaymentMetricNames.java`
>
> **2. Order models**
> - `order/OrderItem.java` (new): SKU, quantity, unit price, and the computed item total
> - `order/Order.java` (new): customer, items, status, shipping cost
> - `order/OrderCreatedEvent.java` (new)
> - `order/OrderItemTest.java` (new): item total calculation, and rejecting a quantity of zero or less
>
> **3. Shipping cost calculation**
> - `order/ShippingCalculator.java` (new)
> - `order/ShippingCalculatorTest.java` (new): free when domestic and over the threshold, charged at or under the threshold, always charged for international orders
>
> **4. Order repository and event publisher contracts**. No test (interfaces only)
> - `order/OrderRepository.java` (new)
> - `order/OrderEventPublisher.java` (new)
>
> **5. Order creation service**
> - `order/CreateOrderService.java` (new)
> - `order/CreateOrderServiceTest.java` (new): success, empty items, customer not found, customer blocked, no event when the save fails, and the metrics recorded in each case
> - Logs: info when an order is created, debug when it's rejected. Metrics: `orders.created`, and `orders.rejected` tagged by `reason`. Both use the SLF4J and Micrometer setup the other services use.
>
> **6. REST endpoint**
> - `order/OrderController.java` (new)
> - `order/CreateOrderRequest.java` (new)
> - `order/OrderControllerTest.java` (new): 201 on success, 400 on validation errors, 422 for a blocked customer
>
> Tasks 1 and 4 have no test because they contain no behavior. Tell me if you want tests there anyway.
>
> Please review the plan. I'll start task 1 when you approve it.

## Clean code

### Indentation levels

```java
public void process(List<Order> orders) {
    for (Order order : orders) {                  // level 1
        if (order.isPending()) {                  // level 2
            for (OrderItem item : order.items()) {  // level 3
                if (item.isOutOfStock()) {        // level 4: not allowed
                    notifyBackorder(item);
                }
            }
        }
    }
}
```

Refactored with a filter and extracted methods:

```java
public void process(List<Order> orders) {
    for (Order order : orders) {                  // level 1
        processIfPending(order);                  // level 2
    }
}

private void processIfPending(Order order) {
    if (!order.isPending()) {                     // level 1
        return;                                   // level 2
    }
    order.items().stream()
            .filter(OrderItem::isOutOfStock)
            .forEach(this::notifyBackorder);
}
```

### Boolean checks as methods

Before:

```java
if (order.total().compareTo(FREE_SHIPPING_THRESHOLD) > 0 && !order.address().isInternational()) {
    return BigDecimal.ZERO;
}
```

After:

```java
if (isEligibleForFreeShipping(order)) {
    return BigDecimal.ZERO;
}

private boolean isEligibleForFreeShipping(Order order) {
    return isOverFreeShippingThreshold(order) && isDomestic(order);
}

private boolean isOverFreeShippingThreshold(Order order) {
    return order.total().compareTo(FREE_SHIPPING_THRESHOLD) > 0;
}

private boolean isDomestic(Order order) {
    return !order.address().isInternational();
}
```

A condition that is already a single named check stays inline: `if (customer.isBlocked())`.

### Small, specialized methods

Before, one method validates, builds, saves and publishes:

```java
public Order createOrder(CreateOrderRequest request) {
    if (request.items() == null || request.items().isEmpty()) {
        throw new IllegalArgumentException(OrderErrors.EMPTY_ORDER);
    }
    Customer customer = customerRepository.findById(request.customerId())
            .orElseThrow(() -> new CustomerNotFoundException(request.customerId()));
    if (customer.isBlocked()) {
        throw new BusinessException(OrderErrors.customerBlocked(customer.id()));
    }
    Order order = orderRepository.save(Order.from(customer, request.items()));
    eventPublisher.publish(new OrderCreatedEvent(order.id()));
    return order;
}
```

After, each step is a named method, and the public method reads like the rule it implements:

```java
public Order createOrder(CreateOrderRequest request) {
    validateHasItems(request);
    Customer customer = findCustomerAllowedToOrder(request.customerId());
    Order order = orderRepository.save(Order.from(customer, request.items()));
    eventPublisher.publish(new OrderCreatedEvent(order.id()));
    return order;
}

private void validateHasItems(CreateOrderRequest request) {
    if (hasNoItems(request)) {
        throw new IllegalArgumentException(OrderErrors.EMPTY_ORDER);
    }
}

private boolean hasNoItems(CreateOrderRequest request) {
    return request.items() == null || request.items().isEmpty();
}

private Customer findCustomerAllowedToOrder(long customerId) {
    Customer customer = customerRepository.findById(customerId)
            .orElseThrow(() -> new CustomerNotFoundException(customerId));
    if (customer.isBlocked()) {
        throw new BusinessException(OrderErrors.customerBlocked(customerId));
    }
    return customer;
}
```

## Logs and metrics

`createOrder` from the example above, with logs and metrics added in a project that uses SLF4J and Micrometer:

```java
@Slf4j
public class CreateOrderService {

    // fields and constructor omitted

    public Order createOrder(CreateOrderRequest request) {
        validateHasItems(request);
        Customer customer = findCustomerAllowedToOrder(request.customerId());
        Order order = orderRepository.save(Order.from(customer, request.items()));
        eventPublisher.publish(new OrderCreatedEvent(order.id()));
        meterRegistry.counter(OrderMetricNames.ORDERS_CREATED).increment();
        log.info("Order created orderId={} customerId={} items={}", order.id(), customer.id(), order.items().size());
        return order;
    }

    private Customer findCustomerAllowedToOrder(long customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new CustomerNotFoundException(customerId));
        if (customer.isBlocked()) {
            log.debug("Rejecting order, customer is blocked customerId={}", customerId);
            countRejection(OrderMetricNames.REASON_CUSTOMER_BLOCKED);
            throw new BusinessException(OrderErrors.customerBlocked(customerId));
        }
        return customer;
    }

    private void countRejection(String reason) {
        meterRegistry.counter(OrderMetricNames.ORDERS_REJECTED, OrderMetricNames.TAG_REASON, reason).increment();
    }
}
```

- **info:** one line per created order, with ids and a count. It doesn't include the customer's email or address.
- **debug:** why an order was rejected.
- **Metrics:** names and tags come from `OrderMetricNames`, created in task 1. The `reason` tag has a small, fixed set of values, never the customer id.
- **Tests:** in the unit test, a `SimpleMeterRegistry` passed to the service lets the test check `orders.created` and `orders.rejected{reason=customer_blocked}`.
