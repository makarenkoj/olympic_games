require "csv"
require_relative "constant.rb"

class CSVParser

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
    year.to_s == "NA" || age.to_s == "NA" ? "null" : year.to_i - age.to_i
  end

  # If params is undefined - set null.
  def set_null(params)
    params == "NA" ? "null" : params
  end

  # remove dash and number in the end of the name
  def remove_dash_and_number(variable)
    variable.sub(/-\d/, "").strip
  end

  # read csv file
  def read_csv(games, sports, events, teams, athletes, results)
    CSV.parse(File.readlines(CSV_FILE).drop(1).join) { |row|
      if row[9] != "1906"
        unless games.key?([row[9], SEASONE_TYPES[row[10].capitalize.intern]])
          games[[row[9], SEASONE_TYPES[row[10].capitalize.intern]]] = [
            games.length + 1, row[11]
          ]
        end

        unless teams.key?(row[7])
          teams[row[7]] = [
            teams.length + 1, remove_dash_and_number(row[6])
          ]
        end

        unless sports.key?(row[12])
          sports[row[12]] = [
            sports.length + 1
          ]
        end

        unless events.key?(row[13])
          events[row[13]] = [
            events.length + 1
          ]
        end

        unless athletes.key?(row[0])
          athletes[row[0]] = [
            delete_brackets(row[1]), set_null(row[2]), calculate_of_birth(row[9], row[3]), params_json(row[4], row[5]), teams[row[7]][0]
          ]
        end

        results[results.length + 1] = [
          row[0].to_i, games[[row[9], SEASONE_TYPES[row[10].capitalize.intern]]][0], sports[row[12]][0], events[row[13]][0], MEDAL_TYPES[row[14].downcase.intern]
        ]
      end
    }

    p "end parsing #{Time.now.strftime("%k:%M:%S")}"
  end
end
