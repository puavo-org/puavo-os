require 'sqlite3'

module PermStore

  DB = SQLite3::Database.new('controller.sqlite3')
  begin
    DB.execute <<'EOF'
CREATE TABLE IF NOT EXISTS Report (
  name TEXT NOT NULL,
  host TEXT NOT NULL,
  json TEXT NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
EOF
  rescue SQLite3::BusyException
    sleep 1
    retry
  end

  def self.add_report(name, host, json)
    sql = 'INSERT INTO Report(name, host, json) VALUES (?, ?, ?);'
    DB.execute(sql, name, host, json)
  end

end
