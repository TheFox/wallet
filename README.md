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
- VI/editor import mode. (CSV)

## Install

The preferred method of installation is via RubyGems.org:  
<https://rubygems.org/gems/thefox-wallet>

	gem install thefox-wallet

or via `Gemfile`:

	gem 'thefox-wallet', '~>0.9'

Use it in your sources:

	require 'thefox-wallet'

## Project Links

- [Blog Post about Wallet](http://blog.fox21.at/2015/07/09/wallet.html)
- [Gem](https://rubygems.org/gems/thefox-wallet)
- [Travis CI Repository](https://travis-ci.org/TheFox/wallet)

## License
Copyright (C) 2015 Christian Mayer <http://fox21.at>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
