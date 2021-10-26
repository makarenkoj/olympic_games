# frozen_string_literal: true

require_relative "csv_parser"
require_relative "import_db"

olympic = []

p "import start #{Time.now.strftime("%k:%M:%S")}"

parser = CSVParser.new
parser.read_csv(olympic)

import = ImportDataBase.new
import.import_sql(olympic)

p "done #{Time.now.strftime("%k:%M:%S")}"
