
# Validating User Input

In most cases, your frontend UI will be built based on data from the backend, but it's still important that we validate user input and present validation errors if necessary.  

## Automatic Validation

There are several common cases where we handle validation automatically for you, without any extra work on your part.

### Clauses

Every condition that uses [clauses](/conditions/clauses/) will validate that the user has selected one of the clauses allowed by the developer.

### OptionCondition

The OptionCondition will validate that the user has chosen one of the allowed values.

### DateCondition

The DateCondition will automatically validate that the inputs passed to it are of the appropriate type. If two dates are required, it will ensure that two dates are present. 

If your user chooses a relative clause, the DateCondition will validate that the first input is a number and the second input is a direction ("ago" or "from now"). 

## Custom Validation
Not yet implemented