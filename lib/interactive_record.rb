require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA TABLE_INFO(#{table_name})"
    names = DB[:conn].execute(sql).map{|hash| hash['name']}
    names.compact
  end

  def initialize(options={})
    options.each{|key, value| self.send("#{key}=", value)}
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if{|name| name == 'id'}.join(', ')
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |name|
      values << "'#{self.send(name)}'" unless self.send(name) == nil
    end
    values.join(', ')
  end

  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    self
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = ?
    SQL
    row = DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute)
    attribute.map do |key,value|
      sql = <<-SQL
        SELECT * FROM #{self.table_name}
        WHERE #{key} = ?
      SQL
      DB[:conn].execute(sql, value)[0]
    end
  end
end
