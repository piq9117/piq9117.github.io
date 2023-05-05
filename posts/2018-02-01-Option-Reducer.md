---
title: Typescript - Using Option Type in Redux Reducer
---

One of my concerns with reducers in redux is it can grow to an infinite size. 
Which I noticed is currently happening to our reducers.

Since I can't show our code here's a contrived example instead.

```javascript
  const listLens = Lens.fromProp<State, "list">("list");
  const newUserLens = Lens.fromProp<State, "newUser">("newUser");
  const initUserLens = Lens.fromProp<NewUserState, "initial">("initial");
  const confrmUserLens = Lens.fromProp<NewUserState, "confirmed">("confirmed");

  const isBlankUser = (u: User) ⇒ u.firstName ≠ undefined;

  const setList = (state: State, action: RAction<Response>) ⇒
    listLens.modify(l ⇒
      filter(isBlankUser)(concat(action.payload.items, l))
    )(state);

  const setInitial = (state: State, action: RAction<User>) ⇒
    newUserLens
      .compose(initUserLens)
      .modify(x ⇒ merge(x, action.payload))(state);

  const setConfirmed = (state: State) ⇒
    newUserLens
      .compose(confrmUserLens)
      .modify(x ⇒
        merge(x, newUserLens.compose(initUserLens).get(state))
      )(state);

  const setEdited = (state: State, action: RAction<Res<User>>) ⇒
    state;

  const resetNewUser = (state: State) ⇒
    newUserLens.set(newUserLens.get(initialState))(state);

  const resetState = (state: State) ⇒ initialState;

  export const userList = (state: State = initialState, action: Action) ⇒ {
    switch (action.type) {
      case SET_USER_LIST:
        return setList(state, action);

      case SET_INITIAL_NEW_USER:
        return setInitial(state, action);

      case SET_CONFIRMED_NEW_USER:
        return setConfirmed(state, action);


      case SET_EDITED_USER:
        return setEditedUser(state, action);
        
      CASE RESET_NEW_USER_STATE:
        return resetNewUser(state, action);

      case RESET_STATE:
        return resetState(state);

      // imagine more case statements here. Maybe 50 more...

      default:
        return state;
    }
  };
```
As you can see it can grow to have more lines!

Luckily, I found this [article][better-reducers] by Vinicius Gomes. It talks how you can
reduce the boilerplate in your reducer by using the `Maybe`{.codeLine} type. It will get rid of
the ever growing size of `case`{.codeLine}s in a typical reducer that is written with a `switch`{.codeLine}
statement.

The code snippet above can turn into this.

```javascript
  import { fromNullable } from "fp-ts/lib/Option";
  import { filter, concat, merge } from "ramda";
  import { Lens } from "monocle-ts";
  import { State, Action, RAction, User, Res, NewUserState } from "./types";
  import { initialUser, initialNewUser } from "./initial-values";

  const initialState: State = {
    list: [initialUser],
    newUser: {
      initial: initialNewUser,
      confirmed: initialNewUser
    },
    selectedUser: initialUser
  };

  type Response = Res<ReadonlyArray<User>>;

  interface Handlers {
    [type: string]: (s: State, a: Action) ⇒ State;
  }

  const listLens = Lens.fromProp<State, "list">("list");
  const newUserLens = Lens.fromProp<State, "newUser">("newUser");
  const initUserLens = Lens.fromProp<NewUserState, "initial">("initial");
  const confrmUserLens = Lens.fromProp<NewUserState, "confirmed">("confirmed");

  const isBlankUser = (u: User) ⇒ u.firstName ≠ undefined;

  const SET_USER_LIST = (state: State, action: RAction<Response>) ⇒
    listLens.modify(l ⇒
      filter(isBlankUser)(concat(action.payload.items, l))
    )(state);

  const SET_INITIAL_NEW_USER = (state: State, action: RAction<User>) ⇒
    newUserLens
      .compose(initUserLens)
      .modify(x ⇒ merge(x, action.payload))(state);

  const SET_CONFIRMED_NEW_USER = (state: State) ⇒
    newUserLens
      .compose(confrmUserLens)
      .modify(x ⇒
        merge(x, newUserLens.compose(initUserLens).get(state))
      )(state);

  const SET_EDITED_USER = (state: State, action: RAction<Res<User>>) ⇒
    state;

  const RESET_NEW_USER = (state: State) ⇒
    newUserLens.modify(() ⇒ newUserLens.get(initialState))(state);

  const RESET_STATE = (state: State) ⇒ initialState;

  const actionHandlers: Handlers = {
    SET_USER_LIST,
    SET_INITIAL_NEW_USER,
    SET_CONFIRMED_NEW_USER,
    SET_EDITED_USER,
    RESET_NEW_USER,
    RESET_STATE
  };

  export const userList = (state: State = initialState, action: Action) ⇒
    fromNullable(actionHandlers[action.type])
      .map(f ⇒ f(state, action))
      .getOrElseValue(state);
```
Instead of using the `Maybe`{.codeLine} type I used `Option`{.codeLine} type from [fp-ts][fp-ts]. 
`Option`{.codeLine} and `Maybe`{.codeLine} types are synonymous.

According to [fp-ts][fp-ts-option]

#### fromNullable
```javascript
<A>(a: A | null | undefined): Option<A>
```
In this context, if `actionHandlers[action.type]`{.codeLine} comes up `undefined`{.codeLine} it will return
the data constructor `None`{.codeLine}, and `getOrElseValue`{.codeLine} in the bottom will return `state`{.codeLine}
if ever there is `None`{.codeLine} in the chain.

Here's the type signature of `getOrElseValue`{.codeLine}

#### getOrElseValue
```javascript
(a: A): A
```

When an incoming `type`{.codeLine} matches one of my functions in `actionHandlers`{.codeLine} then `map`{.codeLine}
will apply that function to `state`{.codeLine}.

Finally, I change the names on my reducer functions, and delete the long line of imported constants.

## Conclusion
I've changed the reducer body to have less moving parts. Instead of having many `case`{.codeLine} statements
it now only has those 3 chained function calls. I also got rid of importing the action-creator 
constants(i.e `SET_USER_LIST`{.codeLine}).

[better-reducers]:http://vvgomes.com/better-reducers/
[fp-ts]:https://github.com/gcanti/fp-ts
[fp-ts-option]:https://github.com/gcanti/fp-ts/blob/master/docs/api/md/Option.md
