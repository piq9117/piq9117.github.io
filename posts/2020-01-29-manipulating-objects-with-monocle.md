---
title: Typescript - Manipulating Deeply Nested Immutable Objects with Lenses
---

Javascript doesn't really have an immutable object but with typescript I can
prevent compilation if there's a rogue function that will try to mutate an object.

Let's say I have this object, and let's assume the values are always there
because if I start talking about the possibility of `null`{.codeLine} then I have to talk
about prisms. So let's take it easy and stick with lenses for now.
```javascript
const bankIdentity: BankIdentity = {
  account: {
    owner: {
      address: {
        data: {
          city: "Malakoff",
          region: "NY",
          street: "2992 Cameron Road",
          postal_code: "14236",
          country: "US"
        },
        primary: true
      }
    }
  }
};
```
It has this type.
```javascript
interface Address {
  readonly city: string;
  readonly region: string;
  readonly street: string;
  readonly postal_code: string;
  readonly country: string;
}

interface AddressData {
  readonly data: Address;
  readonly primary: boolean;
}

interface Owner {
  readonly address: AddressData;
}

interface Account {
  readonly owner: Owner;
}

interface BankIdentity {
  readonly account: Account;
}
```
### Accessing a value
Without using any library I can manipulate this object no problem.
When I want to access a field, I just do the dot syntax and it gives me the
value of that field.
```javascript
const cityRes =  bankIdentity.account.owner.address.data.city;

// "Malakoff"
```
### Setting a new value and returning the whole object
It becomes a hassle when I have to set a new value.

```javascript
const cityRes = Object.assign({}, bankIdentity, { 
    account: { 
        owner: { 
            address: { 
                data: Object.assign({}, bankIdentity.account.owner.address.data, { 
                    city: "Another City"
                }) 
            } 
        } 
    }
});

// { account:
//    { owner:
//       { address:
//          { data:
//             { city: 'Another City',
//               region: 'NY',
//               street: '2992 Cameron Road',
//               postal_code: '14236',
//               country: 'US' 
//             } 
//         } 
//      } 
//  } 
//}
```

### Applying a function and returning the whole object
Same ugliness can be seen when applying a function to the field.
```javascript
const capitalize = (s: string): string => s.toUpperCase();

const cityRes = Object.assign({}, bankIdentity, {
    account: {
      owner: {
        address: {
          data: Object.assign({}, bankIdentity.account.owner.address.data, { 
            city:  capitalize(bankIdentity.account.owner.address.data.city) 
          })
        } 
      } 
    }
  });

// { account:
//    { owner:
//       { address:
//          { data:
//             { city: 'MALAKOFF',
//               region: 'NY',
//               street: '2992 Cameron Road',
//               postal_code: '14236',
//               country: 'US' 
//             } 
//         } 
//      } 
//  } 
//}
```
## [monocle-ts][monocle-ts]

Lenses to the rescue! Unfortunately I don't think it's possible or at least easy
to generate lenses based on the objects like what [makeLenses][makeLenses] does, 
so I have to hand code all of them.
```javascript
import { Lens } from "monocle-ts";

const account = Lens.fromProp<Bankdentity>()("account");
const owner = Lens.fromProp<Account>()("owner");
const address = Lens.fromProp<Owner>()("address");
const data = Lens.fromProp<AddressData>()("data");
const city = Lens.fromProp<Address>()("city");
const region = Lens.fromProp<Address>()("region");
const street = Lens.fromProp<Address>()("street");
const postalCode = Lens.fromProp<Address>()("postal_code");
const country = Lens.fromProp<Address>()("country");
```

Well... accessing a value with monocle-ts looks pretty verbose.
```javascript
const cityRes = account
  .compose(owner)
  .compose(address)
  .compose(data)
  .compose(city)
  .get(bankIdentity);

// "Malakoff"
```
I guess I can do it like this
```javascript
const cityRes = Lens.fromPath<BankIdentity>()(["account", "owner", "address", "data", "city"]).get(bankIdentity);

// "Malakoff"
```
but I think it's better to just use the dot syntax, at least in my opinion.

Lenses shine when it comes to updating and applying a function to a deeply
nested value.

### Setting a value and returning the whole object
```javascript
const cityRes = account
  .compose(owner)
  .compose(address)
  .compose(data)
  .compose(city)
  .set("Another City")(bankIdentity);

// { account:
//    { owner:
//       { address:
//          { data:
//             { city: 'Another City',
//               region: 'NY',
//               street: '2992 Cameron Road',
//               postal_code: '14236',
//               country: 'US' 
//             } 
//         } 
//      } 
//  } 
//}
```
I think that looks a lot cleaner than using `Object.assign`{.codeLine}.

### Applying a function and returning the whole object
Yep. That definitely looks a lot cleaner.
```javascript
const capitalize = (s: string): string => s.toUpperCase();

const cityRes = account
  .compose(owner)
  .compose(address)
  .compose(data)
  .compose(city).modify(capitalize)(bankIdentity);

// { account:
//    { owner:
//       { address:
//          { data:
//             { city: 'MALAKOFF',
//               region: 'NY',
//               street: '2992 Cameron Road',
//               postal_code: '14236',
//               country: 'US' 
//             } 
//         } 
//      } 
//  } 
//}
```

### Resources on Lenses

[Optics by Example by Chris Penner][optics-by-example]

[monocle-ts][monocle-ts]

[optics-by-example]:https://leanpub.com/optics-by-example
[monocle-ts]:https://github.com/gcanti/monocle-ts
[makeLenses]:https://hackage.haskell.org/package/lens-4.18.1/docs/Control-Lens-Combinators.html#v:makeLenses
