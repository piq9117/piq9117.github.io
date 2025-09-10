---
title: Learning Rust Efficiently as an Experienced Programmer
---

The [rust book](https://doc.rust-lang.org/book) has been effective at guiding me learn rust features but it belabors on some concepts because it is catered for beginner programmers. 

Most of the concepts in the early chapters are already familiar and I'm the type of learner that learn by example so after a couple of chapters I jumped to chapter 12; [An I/O Project: Building a Command Line Program](https://doc.rust-lang.org/book/ch12-00-an-io-project.html). This chapter aggregates a lot of the concepts from earlier chapters like code modularization, ownership, traits, and lifetimes.

I'll go through my approach in implementing the example in chapter 12. When a language implements sum types and pattern matching, I try to utilize it as much as I can instead of using booleans. The code flow of declaring a variable, mutating, then returning it is also not my style. So I jumped to [chapter 13](https://doc.rust-lang.org/book/ch13-00-functional-features.html) to peek at Iterators.

I'm not saying this function is bad. The mutation is localized, and rust lifetimes prevents me from doing dumb mutations all over the code. It is just not my style. 
```rust
pub fn search_case_insensitive<'a>(
    query: &str,
    contents: &'a str,
) -> Vec<&'a str> {
    let query = query.to_lowercase();
    let mut results = Vec::new();

    for line in contents.lines() {
        if line.to_lowercase().contains(&query) {
            results.push(line);
        }
    }

    results
}

pub fn search<'a>(query: &str, contents: &'a str) -> Vec<&'a str> {
    let mut results = Vec::new();

    for line in contents.lines() {
        if line.contains(query) {
            results.push(line);
        }
    }

    results
}
```

Usage of the 2 functions 
```rust
    let results = if config.ignore_case {
        search_case_insensitive(&config.query, &contents)
    } else {
        search(&config.query, &contents)
    };
```

I try to avoid booleans as much as I can because I've been a victim of [boolean blindness](https://existentialtype.wordpress.com/2011/03/15/boolean-blindness) so many times. So if I can express a value in terms of sum types, I will do it and avoid booleans. Plus, sum types are discussed early in the book [chapter 6](https://doc.rust-lang.org/book/ch06-00-enums.html)

Below is my approach. To avoid booleans, I first declare a sum type called `CaseSensitivity`{.codeLine}.
```rust
pub enum CaseSensitivity {
    Sensitive,
    Insensitive,
}
```

Instead of implementing 2 functions, I've unified the implementation and utilized the sum type I've defined.
```rust
pub fn search<'a>(
    query: &str,
    contents: &'a str,
    case_sensitivity: &CaseSensitivity,
) -> Vec<&'a str> {
    contents
        .lines()
        .filter(|line| match case_sensitivity {
            CaseSensitivity::Insensitive => line.to_lowercase().contains(&query.to_lowercase()),
            CaseSensitivity::Sensitive => line.contains(query),
        })
        .collect()
}
```
I'm not saying this is the right way of implementing this function. This is just my own style.

The book is a solid resource for learning rust but can feel slow-paced. So if you're an experienced programmer and learn by example skip ahead and expexpirement! [chapter 12](https://doc.rust-lang.org/book/ch12-00-an-io-project.html) and [chapter 21](https://doc.rust-lang.org/book/ch21-00-final-project-a-web-server.html) are great chapters to start with.

