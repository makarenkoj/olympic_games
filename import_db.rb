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
    @teams = []
    @athletes = []
  end

  def create_sports_table(olympic)
    olympic[1...-1].each { |array| @sports << array[11] }
    @sports.uniq
  end

  def create_events_table(olympic)
    olympic[1...-1].each { |array| @events << array[12] }
    @events.uniq
  end

  # 1 record  for the current NOC
  def create_teams_table(olympic)
    @teams = olympic[1...-1].map { |array| array[5..6] }.uniq { |team| team.last }
  end

  # If the Game for the certain year and season took place in more than 1 city,
  # please add 1 record to the game table and put all city names to the city field separated by comma.
  def create_games_table(olympic)
    temporary = olympic[1...-1].map { |array| array[8..10] }.uniq
    temporary.each { |a| @games << [a[0], a[1], temporary.map { |b| b[2] if a[0..1] == b[0..1] }.compact.join(", ")] }
    @games.uniq
  end

  def create_athletes_table(olympic)
    @athletes = olympic[1...-1].map { |array|
      [
        array[1],
        array[2],
        array[3],
        array[4],
        @teams.map.with_index { |team, index| index + 1 if team[1] == array[6] }.compact[0]
      ]
    }.uniq
  end

  def create_results_table(olympic)
    olympic[1...-1].map { |array|
      [
        @athletes.map.with_index { |athlete, index| index + 1 if athlete[0] == array[1] }.compact[0],
        @games.map.with_index { |game, index| index + 1 if game[0] == array[8] && game[1] == array[9] }.compact[0],
        @sports.map.with_index { |sport, index| index + 1 if sport == array[11] }.compact[0],
        @events.map.with_index { |event, index| index + 1 if event == array[12] }.compact[0],
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
