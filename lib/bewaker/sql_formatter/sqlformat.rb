module Bewaker

  INDENT_SIZE = 4

  class SqlFormatter
    # Converts one-line sql strings copied from the logs in the terminal
    # to a more human readable format based on the parenthesis.
    def self.format
      sql = File.read("sql_formatter/input.sql")

      return unless sql

      stack = []
      formatted = []

      sql.split("").each do |char|
        if char == "("
          formatted.push char
          formatted.push "\n"
          ((stack.size + 1) * INDENT_SIZE).times { formatted.push " " }
          stack.push 1
        elsif char == ")"
          stack.pop
          formatted.push "\n"
          ((stack.size) * INDENT_SIZE).times { formatted.push " " }
          formatted.push char
        else
          formatted.push char
        end
      end

      File.open("sql_formatter/output.sql", 'w') do |file|
        file.write(formatted.join)
      end
    end
  end
end

Opa::SqlFormatter.format
