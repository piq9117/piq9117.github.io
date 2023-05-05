---
title: Haskell - Boolean Blindness == True
---

What does the title even mean? `True`{.codeLine}? for 
what? Good? Bad? Useful? If it was `False`{.codeLine}, would we see any meaning?

Even the state of a light bulb cannot be properly represented by booleans. Would
`True`{.codeLine} mean the light is on? or would it mean off?

What if the decision on whether Boolean Blindess is bad or good is represented
with a sum type
```haskell
data Decision 
  = Bad
  | Good
  deriving Show

makeDecision :: Decision -> Text
makeDecision decision = case decision of
  Bad -> "Boolean blindness is " <> ( show Bad ) <> "!"
  Good -> "Boolean blindess is " <> ( show Good ) <> "!"
```
I think using the sum type gives it meaning. Now we can make a decision
about Boolean Blindess.

I lessen confusion in my code by using booleans conservatively.
