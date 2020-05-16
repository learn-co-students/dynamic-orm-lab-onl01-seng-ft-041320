require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        sql = "pragma table_info('#{table_name}')"
        DB[:conn].execute(sql).map {|row| row["name"]}.compact
    end

    def initialize(attributes={})
        attributes.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end
  
    def col_names_for_insert
        self.class.column_names.delete_if {|name| name == "id"}.join(", ")
    end

    def values_for_insert
        without_id = self.class.column_names.delete_if {|name| name == "id"}
        without_id.map {|name| "'#{self.send("#{name.to_sym}")}'"}.join(", ")
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name == ?"

        DB[:conn].execute(sql, name)
    end

    def self.find_by(attribute)
        sql = "SELECT * FROM #{self.table_name} WHERE #{attribute.keys[0]} == '#{attribute.values[0]}'"

        result = DB[:conn].execute(sql)
    end

end