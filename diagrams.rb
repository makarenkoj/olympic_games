require "./constant.rb"
require "./data_base_connector.rb"

class Diagrams
  def initialize
    @data_base = DataBaseConnector.new.connect(DB_FILE)
    @input_hash = {}
    @max_count = []
  end

  def print_rectangle(count)
    result = count.to_f / @max_count.max * 100 * RECTANGLE / 100
    "█" * result
  end

  # Params: season [winter|summer] NOC medal_name [gold|silver|bronze] (in any order).
  # use table teams(noc) teams.id, athletes(team_id) athletes.id, games(season) games.id, resilts(athletes.id, games.id) medal
  # return year and amount medal: Year  Amount
  #                              1896  █████
  #                              1900  ███
  #                              1904
  #                              1908  ████████
  def amount_of_medals(medal, season, noc)
    medal = medal == 4 ? "IN (1, 2, 3)" : "IN (#{medal})"

    @data_base.execute(
      "SELECT DISTINCT year, COUNT(noc_name) medals from games
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
      ORDER BY year ASC"
    )
  end

  def print_amount_of_medals(medal, season, noc)
    results = amount_of_medals(medal, season, noc)
    @max_count = results.map { |result| result[1] }
    puts "Year  Amount"
    results.each { |result| puts "#{result[0]} #{print_rectangle(result[1])}" }
  end

  # check the input if the amount of medals function is selected
  def medal_array(user_input_array)
    user_input_array.each do |item|
      if !MEDAL_TYPES[item.downcase.intern].nil?
        @input_hash[1] = (MEDAL_TYPES[item.downcase.intern]).to_s
      elsif !SEASONE_TYPES[item.capitalize.intern].nil?
        @input_hash[2] = (SEASONE_TYPES[item.capitalize.intern]).to_s
      elsif item.size == 3
        @input_hash[3] = item.upcase
      end
    end

    @input_hash[1] = 4 unless @input_hash.include?(1)

    if @input_hash[2].nil?
      puts ERRORS[:season]
    elsif @input_hash[3].nil?
      puts ERRORS[:noc]
    else
      print_amount_of_medals(@input_hash[1], @input_hash[2], @input_hash[3])
    end
  end

  # Params: season [winter|summer] year medal_type [gold|silver|bronze] (in any order).
  # games(season, year) game_id, result(game_id) team_id, medal
  # NOC   Amount
  # URK   ██████████████████████████████████████████████████
  # USA   ████████████████████████████████████████
  # RUS   ███████████████████████████████████████
  # UGA   ██████████████████████████████

  def top_teams(season, year, medal_type)
    medal = medal_type == 4 ? "IN (1, 2, 3)" : "IN (#{medal_type})"
    condition = year == 0 ? "" : "year = #{year} AND "

    @data_base.execute(
      "SELECT noc_name, COUNT(medal) medals
                FROM results
                LEFT JOIN athletes ON results.athlete_id = athletes.id
                LEFT JOIN games ON results.game_id = games.id
                LEFT JOIN teams ON athletes.team_id = teams.id
                WHERE #{condition}season = #{season}
                AND medal #{medal}
                GROUP BY noc_name
                ORDER BY count(medal) DESC"
    )
  end

  # Show resulting chart only for those teams, that have more than average result:
  # if average amount for all teams is 200 - show only teams with more than 200 medals.
  def print_top_teams(season, year, medal_type)
    teams = top_teams(season, year, medal_type)
    @max_count = teams.map { |teams| teams[1] }
    average_result = @max_count.sum / teams.count

    puts "NOC   Amount"
    teams.each { |team| puts "#{team[0]}: #{print_rectangle(team[1])}" if team[1] >= average_result }
  end

  # check the input if the top teams function is selected
  def top_team_array(user_input_array)
    user_input_array.each do |a|
      if !SEASONE_TYPES[a.capitalize.intern].nil?
        @input_hash[1] = (SEASONE_TYPES[a.capitalize.intern]).to_s
      elsif a.size == 4
        @input_hash[2] = a.to_i
      elsif !MEDAL_TYPES[a.downcase.intern].nil?
        @input_hash[3] = (MEDAL_TYPES[a.downcase.intern]).to_s
      end
    end

    @input_hash[2] = 0 unless @input_hash.include?(2)
    @input_hash[3] = 4 unless @input_hash.include?(3)

    @input_hash[1].nil? ? puts(ERRORS[:season]) : print_top_teams(@input_hash[1], @input_hash[2], @input_hash[3])
  end

  def check_input(user_input_array)
    user_input_array[0] == "medals" ? medal_array(user_input_array) : top_team_array(user_input_array)
  end
end
