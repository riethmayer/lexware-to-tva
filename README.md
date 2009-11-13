# Conversion tool for xml data

This tool converts xml data from the laxware online shop to xml data for the logistic company tva.
Laxware has an export tool, that generates one file with all transactions. As TVA needs each customer, item and order in a different resource, this script generates these resources based on the exporter.

As Laxware is a piece of windows software for the company I wrote this converter,
the encoding of files is windows-1252. TVA needs UTF8 or ISO-8859-1.

So we need to care about the encodings. I'm unsure whether there is a iconf equivalent on windows machines.
That's why I decided to stick to ruby1.9.

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
