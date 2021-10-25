# frozen_string_literal: true

require "csv"
require "standard"
require "sqlite3"

class CSVParser
  SQLITE_DB_FILE = "data/olympic_history.db"
  CSV_FILE = "data/athlete_events.csv"

  # remove any information in round brackets
  def delete_brackets(variable)
    variable.strip.delete('\"').sub(/\s*\(.+\)$/, "")
  end

  # string field that contains JSON in athletes params
  def params_json(height, weight)
    result = {}
    result[:weight] = weight if weight != "NA"
    result[:height] = height if height != "NA"
    result.to_s
  end

  # Year of birth
  def calculate_of_birth(year, age)
    if year.to_s == "NA" || age.to_s == "NA"
      "null"
    else
      year.to_i - age.to_i
    end
  end

  # If params is undefined - set null.
  def set_null(params)
    params == "NA" ? "null" : params
  end

  # remove dash and number in the end of the name
  def remove_dash_and_number(variable)
    variable.sub(/-\d/, "").strip
  end

  # Season is a enum field: 0 - summer, 1 - winter
  def enum_season(type)
    season_types = {Summer: "0", Winter: "1"}
    season_types[type.intern]
  end

  # Medal is a enum field: 0 - N/A, 1 - Gold, 2 - Silver, 3 - Bronze
  def enum_medal(type)
    medal_types = {NA: "0", Gold: "1", Silver: "2", Bronze: "3"}
    medal_types[type.intern]
  end

  # read csv file
  def read_csv(olympic)
    CSV.foreach(CSV_FILE) { |row|
      if row[9] != "1906"
        olympic << [
          row[0], # id
          delete_brackets(row[1]), # name
          set_null(row[2]), # sex
          calculate_of_birth(row[9], row[3]), # year_of_birth
          # row[3], #age
          params_json(row[4], row[5]), # params
          # row[4] #"Height"
          # row[5] #"Weight"
          remove_dash_and_number(row[6]), # Team"
          row[7], # "NOC"
          row[8], # "Games"
          row[9], # "Year"
          enum_season(row[10]), # "Season"
          row[11], # "City"
          row[12], # "Sport"
          row[13], # "Event"
          enum_medal(row[14]) # "Medal"

        ]
      end
    }

    olympic[1..-1]
  end
end
