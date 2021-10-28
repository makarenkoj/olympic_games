require "standard"
require "sqlite3"

# require_relative "csv_parser"

class ImportDataBase
  DB_FILE = "data/olympic_history.db"

  # import datta base
  def import_sql(games, sports, events, teams, athletes, results)
    db = SQLite3::Database.open(DB_FILE)
    db.results_as_hash = true

    begin
      db.transaction
        games.each { |game| db.execute("INSERT INTO games (id, year, season, city) VALUES (?, ?, ?, ?)", game[1][0], game[0][0], game[0][1], game[1][1]) }
        sports.each { |sport| db.execute("INSERT INTO sports (id, name) VALUES (?, ?)", sport[1].join.to_i, sport[0]) }
        events.each { |event| db.execute("INSERT INTO events (id, name) VALUES (?, ?)", event[1].join.to_i, event[0]) }
        teams.each { |team| db.execute("INSERT INTO teams (id, name, noc_name) VALUES (?, ?, ?)", team[1][0], team[1][1], team[0]) }
        athletes.each { |athlete| db.execute("INSERT INTO athletes (id, full_name, sex, year_of_birth, params, team_id) VALUES (?, ?, ?, ?, ?, ?)", athlete[0].to_i, athlete[1][0], athlete[1][1], athlete[1][2], athlete[1][3], athlete[1][4]) }
        results.each { |result| db.execute("INSERT INTO results (id, athlete_id, game_id, sport_id, event_id, medal) VALUES (?, ?, ?, ?, ?, ?)", result[0], result[1][0], result[1][1], result[1][2], result[1][3], result[1][4]) }
      db.commit
    rescue SQLite3::SQLException => e
      puts "Failed to execute query on database #{DB_FILE}"
      abort e.message
    end
  end
end
