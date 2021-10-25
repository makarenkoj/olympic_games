# frozen_string_literal: true

require_relative "csv_parser"
require_relative "import_db"

olympic = []

parser = CSVParser.new
parser.read_csv(olympic)

import = ImportDataBase.new
import.import_sql(olympic)
