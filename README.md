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
- Categories

## Install

The preferred method of installation is via RubyGems.org:  
<https://rubygems.org/gems/thefox-wallet>

	gem install thefox-wallet

or via `Gemfile`:

	gem 'thefox-wallet', '~>0.17'

Use it in your sources:

	require 'thefox-wallet'

## Options

- `-w`, `--wallet <path>`  
	Base path to a wallet directory. Each wallet has its own directory storing all informations. This option can be used for all comamnds.
- `--id <id>`  
	ID used for a new entry. If an ID is provided no new entry will be added if an entry with the same ID already exists. Use `--force` to overwrite this.
- `-t`, `--title <title>`  
	Title used for a new entry.
- `-d`, `--date <date>`  
	Date used for a new entry.
- `--start <date>`  
	Start-date used for a range.
- `--end <date>`  
	End-date used for a range.
- `-r`, `--revenue <revenue>`  
	Revenue used for a new entry.
- `-e`, `--expense <expense>`  
	Expense used for a new entry.
- `-c`, `--category <category>`  
	Category used for a new entry.
- `-o`, `--comment <comment>`  
	Comment used for a new entry.
- `--import`, `--export`  
	Import/Export CSV
- `-p`, `--path <path>`  
	Path used for `csv` import/export and `html` directory path.
- `-i`, `--interactive`  
	Use some commands interactively.
- `-f`, `--force`, `--no-force`  
	Force (or no force) `add` command. See `--id` option.
- `-v`, `--verbose`  
	Log on debug level.
- `-V`, `--version`  
	Show version.
- `-h`, `--help`  
	Show help page.

## Commands

### Add Command

Add a new entry.

	$ wallet add [-w <path>] [--id <id>] [-r <revenue>] [-e <expense>] [-c <category>] [-o <comment>] [-i] [-f|--no-force] -t|--title <title>

When `--interactive` (`-i`) option is used, parse `%d` with `printf`. Separate multiple `%`-variables with `,`. This feature can be used on template scripts that run the `wallet add` command with pre-defined texts.

For example. To use the following in a template script

	$ wallet add --title 'Income tax %d/Q%d' --interactive

and set the values on interactive input when the command is running.

```bash
$ wallet add --title 'Income tax %d/Q%d' --interactive
title: [Income tax %d/Q%d] 2017,1
```

This would set the title to `Income tax 2017/Q1`. So the input will not be set as value rather than replaced by the variables in the template text. Acting like `printf`.

Expenses are always converted to minus.

Calculations will be `eval`ed as Ruby code. For example:

	$ wallet add --title Test --expense 14+7

The expense will be `-21`. Expenses are always minus.

In the following example the expense will be `-3`:

	$ wallet add --title Test --expense 10-7

The same applies to revenue.

See `AddCommand::revenue` and `AddCommand::expense` functions.

### Categories Command

List all used categories.

	$ wallet categories [-w <path>]

Each entry can have one category. It's planned to implement [Multiple Categories](https://github.com/TheFox/wallet/issues/3) for entries.

You can define the categories yourself. The `list` command has a filter option `-c` to list all entries of a certain category. The `html` command (for generating a HTML output) will also sum all entries for each category. If the category is not set on `add` command the category will be set to `default`. The `default` category will not be shown in list views.

### Clear Command

Clear temp and cache files.

	$ wallet clear [-w <path>]

If the html directory path (`-p`) provided to the `html` command is outside of the wallet base path (`-w`) this directory will **NOT** be deleted by the `clear` command. If the default html directory (`wallet/html`) is used this directory will be removed. This command does **NOT** delete any entries stored at `wallet/data`.

### CSV Command

Import or export to/from CSV file format.

	$ wallet csv [-w <path>] [--import|--export] -p <path>

### HTML Command

Exports a wallet as HTML. List all years in an index HTML file and all months for each year. Generates a HTML file for each month based on entries.

	$ wallet html [-w <path>] [--start <date>] [--end <date>] [-c <category,...>] [-p <path>] [-v]

Option `-c` can take multiple categories separated by `,`.

### List Command

List entries. Per default this command lists all entries of today's date.

	$ wallet list [-w <path>] [-d <YYYY>[-<MM>[-<DD>]]] [-c <category>]

You can either provide a year `YYYY`, a month `YYYY-MM` or a day `YYYY-MM-DD`.

## Dates

Dates (`<date>` or `YYYY-MM-DD`) used in this documentation are not limited to `YYYY-MM-DD` format. You can also use `MM/DD/YYYY`, `DD.MM.YYYY`, `YYYYMMDD`, etc. Dates are parsed by [`Date::parse`](https://ruby-doc.org/stdlib-1.9.3/libdoc/date/rdoc/DateTime.html#method-c-parse).

## Project Links

- [Blog Post about Wallet](http://blog.fox21.at/2015/07/09/wallet.html)
- [Wallet Gem](https://rubygems.org/gems/thefox-wallet)
- [Travis CI Repository](https://travis-ci.org/TheFox/wallet)

## License

Copyright (C) 2015 Christian Mayer <https://fox21.at>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
