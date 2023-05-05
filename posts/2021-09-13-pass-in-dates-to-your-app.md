---
title: Haskell - Short IO Adventures, Dates
---

What's your idea of a perfect date? Some people will say `DD/MM/YYYY`{.codeLine}, 
some will say `MM/DD/YYYY`{.codeLine}, and some `YYYY/MM/DD`{.codeLine}. I have 
no opinion about a perfect date, what I do know of what will ruin dates is if 
you instantiate it inside your "business logic". Before I dig in, I just want to 
say I'm not dictating whether you should or shouldn't do anything particular with 
handling dates. This is what I've learned from my experience. 

Here's a contrived example in yesod. Somewhere in the code `getCurrentTime`{.codeLine}
is called. At first look, this is harmless and fulfills the need of providing
a date to the `User`{.codeLine} record. The effects of this won't be noticed 
until there are date transformations that you want to make assertions on later 
in testing.

```haskell
postUsersRegisterR :: Handler Value
postUsersRegisterR = do
  register <- requireCheckJsonBody :: Handler Register
  userId <- runDB $ insertUser register
  encodeUserId userId

insertUser :: MonadIO m => Register -> SqlPersistT m ( Key User )
insertUser Register{..} = do
  -- time is being instantiated here. Harmless
  now <- liftIO getCurrentTime
  pwdHash <- mkPassword registerPassword
  insert
    $ User registerEmail registerUsername pwdHash "" defaultUserImage now now
```

So let's say there's a date transformation you care about.
```haskell
postUsersRegisterR :: Handler Value
postUsersRegisterR = do
  register <- requireCheckJsonBody :: Handler Register
  userId <- runDB $ insertUser register
  encodeUserId userId

insertUser :: MonadIO m => Register -> SqlPersistT m ( Key User )
insertUser Register{..} = do
  -- time is being instantiated here
  now <- liftIO getCurrentTime
  pwdHash <- mkPassword registerPassword
  insert
    $ User registerEmail registerUsername pwdHash "" defaultUserImage now 
      ( userExpirationDate now )
  where
    userExpirationDate d = ...
```
How am I going to test this? It will be very difficult to assert dates as you can 
imagine. But for illustration, let's see how it looks
```haskell
spec = do
  describe "UserSpec" $ do
    it "something something dates" $ do 
      ( Entity key user ) <- runDB $ insertUser testTime registerUser 
      assertEq "user profile expiration date" 
        ( userAcctExpirationDate user ) undefined -- now what?
```
I can't assert anything because every time `getCurrentTime`{.codeLine} 
is called it will return a new date.

I know this is really contrived, and the solution is very obvious to most of you
but when I was starting out this wasn't obvious to me at all. So I bet there
are people out there who are having the same experience. Learning to watch out for
this early on will help you deal with more complex situations later on.

A solution that helped me out in this situation was to parameterize the date 
input.
```haskell
postUsersRegisterR :: Handler Value
postUsersRegisterR = do
  register <- requireCheckJsonBody :: Handler Register
  now <- liftIO getCurrentTime
  userEntity <- runDB $ insertUser register
  encodeUser userEntity

insertUser :: MonadIO m => UTCTime -> Register -> SqlPersistT m ( Entity User )
insertUser date Register{..} = do
  pwdHash <- mkPassword registerPassword
  insertEntity 
    $ User registerEmail registerUsername pwdHash "" defaultUserImage date 
      ( profileExpirationDate date )
  where
    profileExpirationDate d = ...
```

If for some reason you need different transformations, you can always pass in 
a function.
```haskell
postUsersRegisterR :: Handler Value
postUsersRegisterR = do
  register <- requireCheckJsonBody :: Handler Register
  date <- liftIO getCurrentTime
  userEntity <- runDB $ insertUser someComplexDateTransformation date register
  encodeUser userEntity

someComplexDateTransformation 
  :: HTTPOperation m 
  => UTCTime 
  -> m UTCTime
someComplexDateTransformation = ...

insertUser 
  :: MonadIO m 
  => ( UTCTime -> m UTCTime ) 
  -> UTCTime 
  -> Register 
  -> SqlPersistT m ( Entity User )
insertUser dateTrans date Register{..} = do
  pwdHash <- mkPassword registerPassword
  insertEntity 
    $ User registerEmail registerUsername pwdHash "" defaultUserImage date 
      ( dateTrans date )
```

With this change, tests can be straightforward.
```haskell
spec = do
  describe "UserSpec" $ do
    it "something something dates" $ do 
      ...
      let registerUser = ...
      let testTime = UTCTime ( fromGregorian 2021 9 13 ) ( secondsToDiffTime 0 )
      ( Entity key user ) <- runDB $ insertUser testTime registerUser
      assertEq "user profile expiration date"
        ( userAcctExpirationDate user ) 
        $ UTCTime ( fromGregorian 2022 9 13 ) ( secondsToDiffTime 0 )
```
I think that summarizes my adventure dealing with dates.
