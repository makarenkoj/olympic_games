require "csv"
require "standard"

class CSVParser
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
    season_types = {Summer: 0, Winter: 1}
    season_types[type.intern]
  end

  # Medal is a enum field: 0 - N/A, 1 - Gold, 2 - Silver, 3 - Bronze
  def enum_medal(type)
    medal_types = {NA: 0, Gold: 1, Silver: 2, Bronze: 3}
    medal_types[type.intern]
  end

  # read csv file
  def read_csv(games, sports, events, teams, athletes, results)
    CSV.parse(File.readlines(CSV_FILE).drop(1).join) { |row|
      if row[9] != "1906"
        games[[row[9], enum_season(row[10])]] = [games.length + 1, row[11]] unless games.key?([row[9], enum_season(row[10])])
        teams[row[7]] = [teams.length + 1, remove_dash_and_number(row[6])] unless teams.key?(row[7])
        sports[row[12]] = [sports.length + 1] unless sports.key?(row[12])
        events[row[13]] = [events.length + 1] unless events.key?(row[13])
        athletes[row[0]] = [delete_brackets(row[1]), set_null(row[2]), calculate_of_birth(row[9], row[3]), params_json(row[4], row[5]), teams[row[7]][0]] unless athletes.key?(row[0])
        results[results.length + 1] = [row[0].to_i, games[[row[9], enum_season(row[10])]][0], sports[row[12]][0], events[row[13]][0], enum_medal(row[14])]
      end
    }

    p "end parsing #{Time.now.strftime("%k:%M:%S")}"
  end
end
