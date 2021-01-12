# Nano Skello

## Description

Welcome to the recruitment test for a developper position at [skello.io](https://skello.io)!

This project is a small backend application for managing user work time, and
computing statistics from their workload, such as total work time or monthly wages.

### Setup

Stack: ruby 2.6.5, rails 6, rspec, factory bot, sqlite3

If you are not familiar with managing ruby versions, you can use [rbenv](https://github.com/rbenv/rbenv) to install a specific ruby version.

- Install project dependencies: `bundle install`
- Create database: `rails db:create db:schema:load`

You can also run `rails db:seed` to populate your database with test data.

### Models

- `User` is a member who is registered on the application.
  - A user is identified by a unique, optional email.

- `Shop` is a point of sale.
  - It is identified by a unique name.

- `Contract` binds a `User` to a `Shop`, for a given time range.
  - Users can have multiple contracts in multiple shops!
  - But two contracts for the same user and same shop cannot overlap.
  - A contract can be permanent, which means no end date is defined.
  - A contract also defines the hourly wages amount, which is used to compute the user monthly wages. In this application, the monthly wages are always variable, never a fixed amount.

- `Shift` is a task, assigned to a user, in a given shop, for a given time.
  - Shifts can be unassigned, i.e. there is no user assigned to the shift
  - As well as for contracts, users can have multiple shifts in multiple shops and
two shifts for the same user and same shop cannot overlap.
  - Shifts are divided into three categories: *work*, *paid absence*, and *unpaid absence*. Only *work* and *paid absence* shifts trigger monthly wages.

### Services

The `ShopMonthlyReportGenerateService` is generates a CSV file, with the activity report of a given shop for a given month.


## Before starting

Your task is to implement the missing pieces and make the tests pass, Please note that evaluation criteria also include coding style (readibility, comments, etc.) and performance.

The already provided database schema is correct and don't need to be edited.

You are not allowed to edit the already existing tests, but you can add new ones!

## TODO

### 1. Fix `Contract.active_at`

Have a look at `Contract#active_at` scope, it contains a bug, find it and fix it!
This scope should return all active contracts for a given time window (they overlap with the given time window), keep if mind that permanent contract have no end date defined.
Use the already existing unit tests to ensure your implementation is correct.

### 2. Complete the `Shift` model

Make the `shift_spec.rb` tests pass. You need to implement:

- scopes: `paid`, `assigned`
- methods: `duration`, `duration_in_hours`
- validations

### 3. Write `User#monthly_wages` method.

This method computes the user monthly wages for a given shop AND a given month.
The month is passed as a datetime value.
Use the already existing unit tests to ensure your implementation is correct.

### 4. Write the `ShopMonthlyReportGenerateService` service.

This service generates a CSV file, containing various indicators for a given shop and a given month. Feel free to re-use code you have already written.

A sample file is provided in `spec/export/test_file.csv`.

Use the already existing unit tests to ensure your implementation is correct.

### 5. Polish time!

Ensure all the remaining tests pass.

## Sending your results

Once you are done, please send your project as a zip archive to dev@skello.io, and use the following format for the email subject: `[NanoSkello] YourFirstname YourLastname`.

Please do not open a pull request on the `github.com/skelloapp/nano-skello` repository.

Don't forget to include the `.git` directory in the archive!
