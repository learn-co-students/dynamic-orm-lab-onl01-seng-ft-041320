require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    "#{self.to_s.downcase}s"
  end

  def self.column_names
    sql = "PRAGMA table_info('#{table_name}')"
   
    table_info = DB[:conn].execute(sql)
    column_names = []
   
    table_info.each do |column|
      column_names << column["name"]
    end
   
    column_names.compact
  end
  
  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end 

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", name)
  end

  def initialize(options = {})
    options.each{|k,v| self.send("#{k}=", v)}
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by(attr_hash)
    attr_hash.map do |k,v|
      key = "#{k}"
      value = "#{v}"
      #binding.pry
      if value.to_i.to_s == value
        sql = "SELECT * FROM #{self.table_name} WHERE #{key} = #{value}"
      else
      sql = "SELECT * FROM #{self.table_name} WHERE #{key} = '#{value}'"
      end
      DB[:conn].execute(sql)
    end.first
  end

end