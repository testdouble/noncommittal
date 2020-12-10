# Noncommittal

This gem helps you avoid test pollution in your Rails test suite by preventing
tests from committing records to your Postgres database.

## How to avoid commitment

Add this to your Gemfile, probably grouped with other test gems:

``` ruby
group :test do
  gem "noncommittal"
end
```

Then, in your `test_helper.rb` (or similar), after you require your Rails
environment, just drop this in:

```ruby
Noncommittal.start!
```

This will create an empty table called `noncommittal_no_rows_allowed` and, for
every table in your database, a deferred foreign key constraint that will
effectively prevent any records from being committed outside the test
transaction.

## Do you have commitment issues?

By default, Ruby on Rails tests run each test [in a
transaction](https://guides.rubyonrails.org/testing.html#testing-parallel-transactions)
that is rolled back at the end of each test. This is a performant way to create
proper isolation, preventing tests that save records to the database from
affecting the environment of your other tests.

However, Rails can only enforce this constraint when the test-scoped code
connects to the database via the framework and within that transaction. If a
test were to extend `Minitest::Test` instead of `ActiveSupport::TestCase`, that
test would not benefit from this rollback-only transaction protection. And if
the [subject under
test](https://github.com/testdouble/contributing-tests/wiki/Subject) contains
transaction logic itself, or creates its own database connections, or spawns
child processes, then it's entirely possible that some of your tests will
erroneously commit records to the database, potentially causing [test
pollution](https://github.com/testdouble/test-smells/tree/master/smells/unreliable/litter-bugs).

Over the years, Rubyists have taken several approaches to mitigate this risk,
but most popular solutions have drawbacks:

* Gems like
  [database_cleaner](https://github.com/DatabaseCleaner/database_cleaner) that
  purge your database between tests introduce a per-test runtime cost that is
  much higher than relying on transaction rollbacks
* Bisecting your test suite to identify which test that violates transaction
  safety catches test pollution only after it causes a problem and is separately
  time-consuming
* Adding a before-hook that runs before each test to ensure tables are empty
  won't give you a stack trace to the test that managed to commit inserted
  records

So that's why the noncommittal gem exists! It's fast, will catch this problem as
soon as it's introduced, and will give you an accurate stack trace to the
offending test.

## What if I want to commit to certain tables?

By default, noncommittal will gather the table names of all your models that
descend from `ActiveRecord::Base`, but this may not be what you want (you might
want to exclude certain models or include additional tables). To override this
behavior, you can pass an array of table names to a `tables` keyword argument,
like so:

```ruby
Noncommittal.start!(tables: [:users, :posts])
```

If you simply want to exclude certain tables, you can set the `exclude_tables`
keyword argument:

```ruby
Noncommittal.start!(exclude_tables: [:system_configurations])
```

## Limitations

This only works with Postgres currently. PRs welcome if you can accomplish the
same behavior with other database adapters!

## Acknowledgements

This gem is a codification of [this
tweet](https://twitter.com/searls/status/1336729988498862085?s=20), which itself
was the brainchild of [Matthew Draper](https://github.com/matthewd).

## Code of Conduct

This project follows Test Double's [code of
conduct](https://testdouble.com/code-of-conduct) for all community interactions,
including (but not limited to) one-on-one communications, public posts/comments,
code reviews, pull requests, and GitHub issues. If violations occur, Test Double
will take any action they deem appropriate for the infraction, up to and
including blocking a user from the organization's repositories.

