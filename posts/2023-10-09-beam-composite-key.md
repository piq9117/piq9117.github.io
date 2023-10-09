---
title: Defining composite keys in beam
---

When I'm trying to define a table in beam to represent my database table, I always forget how to define it. So I'm writing it down here. Typically when defining a table in beam it will look like this

```haskell
data UserT = User
  { id :: Columnar f Int32,
    username :: Columnar f Text,
    firstName :: Columnar f Text,
    lastName :: Columnar f Text
  }
```
Then defining it's primary key will look like this

```haskell
instance Table UserT where
  newtype PrimaryKey UserT f = UserId (Columnar f Int32)
    deriving (Generic)
    deriving (Beamable)
  primaryKey = UserId <<< id
```
However, for composite keys it needs to be a little different. Remember, `newtype`{.codeLine} can only represent one value. To represent more than one value, use `data`{.codeLine} definition.
Let's say the primary key for this table will be username, first name, and last name.
```haskell
data UserT = User
  { username :: Columnar f Text,
    firstName :: Columnar f Text,
    lastName :: Columnar f Text
  }

instance Table UserT where
  data PrimaryKey UserT f 
    = UserId 
        (Columnar f Text) 
        (Columnar f Text) 
        (Columnar f Text)
    deriving (Generic)
    deriving (Beamable)
  primaryKey table = 
    UserId table.username table.firstName table.lastName
```
There you have it, future me! I hope you won't struggle trying to forage for this information.
