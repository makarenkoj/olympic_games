# frozen_string_literal: true

require "csv"
require "standard"
require "sqlite3"

require_relative "csv_parser"

class ImportDataBase
  DB_FILE = "data/olympic_history.db"

  def initialize
    @games = []
    @sports = []
    @events = []
  end

  def create_sports_table(olympic)
    olympic.each { |array| @sports << array[11] }
    @sports.uniq
  end

  def create_events_table(olympic)
    olympic.each { |array| @events << array[12] }
    @events.uniq
  end

  # 1 record  for the current NOC
  def create_teams_table(olympic)
    teams = olympic.map { |array| array[5..6] }.uniq { |team| team.last }
  end

  # If the Game for the certain year and season took place in more than 1 city,
  # please add 1 record to the game table and put all city names to the city field separated by comma.
  def create_games_table(olympic)
    temporary = olympic.map { |array| array[8..10] }.uniq
    temporary.each { |a| @games << [a[0], a[1], temporary.map { |b| b[2] if a[0..1] == b[0..1] }.compact] }
    @games.uniq
  end

  def create_athletes_table(olympic)
    db = SQLite3::Database.open(DB_FILE)
    db.results_as_hash = true
    teams_array = db.execute("select * from teams")

    olympic.map { |array|
      [
        array[1],
        array[2],
        array[3],
        array[4],
        teams_array.map { |team| team["id"] if team["noc_name"] == array[6] }.compact[0].to_s
      ]
    }
  end

  def create_results_table(olympic)
    db = SQLite3::Database.open(DB_FILE)
    db.results_as_hash = true

    athletes = db.execute("select * from athletes")
    games = db.execute("select * from games")
    sports = db.execute("select * from sports")
    events = db.execute("select * from events")

    olympic.map { |array|
      [
        athletes.map { |athlete| athlete["id"] if athlete["full_name"] == array[1] }.compact[0],
        games.map { |game| game["id"] if game["year"] == array[8] && game["seasone"] == array[9] }.compact[0],
        sports.map { |sport| sport["id"] if sport["name"] == array[11] }.compact[0],
        events.map { |event| event["id"] if event["name"] == array[12] }.compact[0],
        array[13]
      ]
    }
  end

  # import datta base
  def import_sql(olympic)
    db = SQLite3::Database.open(DB_FILE)
    db.results_as_hash = true

    begin
      db.transaction
        create_sports_table(olympic).each { |sport| db.execute("INSERT INTO sports (name) VALUES (?)", sport) }
        create_events_table(olympic).each { |event| db.execute("INSERT INTO events (name) VALUES (?)", event) }
        create_teams_table(olympic).each { |team| db.execute("INSERT INTO teams (name, noc_name) VALUES (?, ?)", team) }
        create_games_table(olympic).each { |game| db.execute("INSERT INTO games (year, season, city) VALUES (?, ?, ?)", game) }
        create_athletes_table(olympic).each { |athlete| db.execute("INSERT INTO athletes (full_name, sex, year_of_birth, params, team_id) VALUES (?, ?, ?, ?, ?)", athlete) }
        create_results_table(olympic).each { |result| db.execute("INSERT INTO results (athlete_id, game_id, sport_id, event_id, medal) VALUES (?, ?, ?, ?, ?)", result) }
      db.commit
    rescue SQLite3::SQLException => e
      puts "Failed to execute query on database #{DB_FILE}"
      abort e.message
    end
  end
end
