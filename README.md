# Conversion tool for xml data

This tool converts xml data from the laxware online shop to xml data for the logistic company tva.

Laxware has an export tool, that generates one file with all transactions. As TVA needs each customer, item and order in a different resource, this script generates these resources based on the exporter.

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
