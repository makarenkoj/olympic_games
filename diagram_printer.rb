require_relative "diagrams"

user_input = ARGV
Diagrams.new.check_input(user_input)
