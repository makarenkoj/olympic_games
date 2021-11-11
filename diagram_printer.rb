require_relative "diagrams.rb"

user_input = ARGV
Diagrams.new.check_input(user_input)
