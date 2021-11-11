require "sqlite3"

class DataBaseConnector
  def connect(db_file)
    SQLite3::Database.open(db_file)
  end
end
