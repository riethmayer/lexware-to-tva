# Conversion tool for xml data

This tool converts xml data from Lexware Faktura to
a consumable xml-format for the logistics company TVA.

Faktura has an export tool, that generates one file with all transactions.

As TVA needs each customer, item and order in a different resource,
this script generates these resources based on the exporter.

Once TVA has items and customers within their database, it's possible to send
orders only.

Lexware Faktura is a piece of windows software, so the exported files are
encoded in windows-1252. TVA needs UTF-8 or ISO-8859-1, we use UTF-8.

To enable encoding features on a various platforms, we use Ruby1.9.

So please make sure to run the rake task with ruby1.9, otherwise this won't work.
If you're running
    rake test
You would see some errors, that occur in combination with umlauts.

# Installation

  To install this Software on your system, you've got to install ruby, rubygems and rake. All other dependencies will be installed via

    rake install

# Usage

    rake usage   # run this task to get a better overview
    rake convert # this will be the main task for the export

# License

  This work is licensed under a creative commons attribution 3.0 license.
  http://creativecommons.org/licenses/by/3.0/.
  (cc) 2009.  Jan Riethmayer.
