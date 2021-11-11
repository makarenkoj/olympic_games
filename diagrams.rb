require 'byebug' #don`t fogot delete it
require "sqlite3"
require_relative "constant.rb"
require_relative "data_base_connector.rb"

class Diagrams
  def initialize
    @data_base = DataBaseConnector.new.connect(DB_FILE)
    @input_hash = {}
  end

  def print_rectangle(params)
    rectangel = []
    params.to_i.times { rectangel << '█' }
    rectangel.join
  end

  # Params: season [winter|summer] NOC medal_name [gold|silver|bronze] (in any order).
  #use table teams(noc) teams.id, athletes(team_id) athletes.id, games(season) games.id, resilts(athletes.id, games.id) medal
  #return year and amount medal: Year  Amount
  #                              1896  █████
  #                              1900  ███
  #                              1904  
  #                              1908  ████████
  def amount_of_medals(medal, season, noc)
    medal == 4 ? medal = 'IN (1, 2, 3)' :  medal = "IN (#{medal})"

    @data_base.execute("SELECT DISTINCT year, COUNT(noc_name) medals from games
        LEFT JOIN (
        SELECT noc_name, y FROM teams
          LEFT JOIN athletes ON athletes.team_id = teams.id
          INNER JOIN (
            SELECT id, year y from games WHERE games.season = #{season}
          ) AS GAM ON RES.game_id = GAM.id
          INNER JOIN (
            SELECT * from results WHERE results.medal #{medal}
          ) AS RES ON RES.athlete_id = athletes.id
          WHERE noc_name = '#{noc.upcase}'
        ) AS MEDALS ON year = MEDALS.y
        GROUP BY year
        ORDER BY year ASC")
  end

  def print_amount_of_medals(medal, season, noc)
    result = amount_of_medals(medal, season, noc)
    puts 'Year  Amount'
    # result.each { |r| puts "#{r[0]} #{print_rectangle(r[1])}" if r[1] != 0 }
    result.each { |r| puts "#{r[0]} #{print_rectangle(r[1])}" }
  end

  #check the input if the amount of medals function is selected
  def medal_array(user_input_array)
    user_input_array.each { |a|
      if MEDAL_TYPES[a.downcase.intern] != nil
        p a
        @input_hash[1] = "#{MEDAL_TYPES[a.downcase.intern]}"
      elsif SEASONE_TYPES[a.capitalize.intern] != nil
        @input_hash[2] = "#{SEASONE_TYPES[a.capitalize.intern]}"
      elsif a.size == 3
        @input_hash[3] = a.upcase
      end
    }

    @input_hash[1] = 4 unless @input_hash.include?(1)

    print_amount_of_medals(@input_hash[1], @input_hash[2], @input_hash[3])
  end

  # Params: season [winter|summer] year medal_type [gold|silver|bronze] (in any order).
  # games(season, year) game_id, result(game_id) team_id, medal
  # NOC   Amount
  # URK   ██████████████████████████████████████████████████
  # USA   ████████████████████████████████████████
  # RUS   ███████████████████████████████████████
  # UGA   ██████████████████████████████

  def top_teams(season, year, medal_type)
    medal_type == 4 ? medal = "IN (1, 2, 3)" : medal = "IN (#{medal_type})"
    year == 0 ? condition = "" : condition = "year = #{year} AND "

    @data_base.execute("SELECT noc_name, COUNT(medal) medals
                  FROM results
                  LEFT JOIN athletes ON results.athlete_id = athletes.id
                  LEFT JOIN games ON results.game_id = games.id
                  LEFT JOIN teams ON athletes.team_id = teams.id
                  WHERE #{condition}season = #{season}
                  AND medal #{medal}
                  GROUP BY noc_name
                  ORDER BY count(medal) DESC")
  end

  def print_top_teams(season, year, medal_type)
    teams = top_teams(season, year, medal_type)
    puts "NOC   Amount"
    teams.each { |t| puts "#{t[0]}: #{print_rectangle(t[1])}" }
  end

  #check the input if the top teams function is selected
  def top_team_array(user_input_array)
    user_input_array.each { |a|
      if SEASONE_TYPES[a.capitalize.intern] != nil
        @input_hash[1] = "#{SEASONE_TYPES[a.capitalize.intern]}"
      elsif a.size == 4
        @input_hash[2] = a.to_i
      elsif MEDAL_TYPES[a.downcase.intern] != nil
        @input_hash[3] = "#{ MEDAL_TYPES[a.downcase.intern] }"
      end
    }

    @input_hash[2] = 0 unless @input_hash.include?(2)
    @input_hash[3] = 4 unless @input_hash.include?(3)  

    print_top_teams(@input_hash[1], @input_hash[2], @input_hash[3])
  end

  def check_input(user_input_array)
    user_input_array[0] == 'medals' ? medal_array(user_input_array) : top_team_array(user_input_array)
  end
end
