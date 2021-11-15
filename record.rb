require "./lib/csv_parser.rb"
require "./lib/import_db.rb"

games = {}
sports = {}
events = {}
teams = {}
athletes = {}
results = {}

p "start parsing #{Time.now.strftime("%k:%M:%S")}"

parser = CSVParser.new
parser.read_csv(games, sports, events, teams, athletes, results)

p "start import #{Time.now.strftime("%k:%M:%S")}"

import = ImportDataBase.new
import.import_sql(games, sports, events, teams, athletes, results)

p "done #{Time.now.strftime("%k:%M:%S")}"
