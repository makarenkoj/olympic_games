require_relative "csv_parser"
require_relative "import_db"

games = {}
sports = {}
events = {}
teams = {}
athletes = {}
results = {}

p "start parsin #{Time.now.strftime("%k:%M:%S")}"

parser = CSVParser.new
parser.read_csv(games, sports, events, teams, athletes, results)

p "start import #{Time.now.strftime("%k:%M:%S")}"

import = ImportDataBase.new
import.import_sql(games, sports, events, teams, athletes, results)

p "done #{Time.now.strftime("%k:%M:%S")}"
