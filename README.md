# Wallet

A spreadsheet likewise Ruby library to track your finances. Using the best data format ever, YAML. It's designed to host the data offline, e.g. in a Git repository.

## Why this project?

While conventionally programs like Microsoft Excel or [LibreOffice](https://www.libreoffice.org/) uses [proprietary file formats](https://en.wikipedia.org/wiki/Proprietary_format) and [binary files](https://en.wikipedia.org/wiki/Binary_file) to save your data this script uses [YAML](https://en.wikipedia.org/wiki/YAML). YAML is a human-readable data serialization format. This means you can edit the YAML files on any [operating system](https://en.wikipedia.org/wiki/Operating_system) with any text editor.

## Features

- Save revenues/expenses entries monthly.
- List saved entries.
- Import CSV files.
- Export data to CSV.
- Generate HTML summary.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wallet', :git => 'https://github.com/TheFox/wallet', :tag => 'v0.5.1'
```
