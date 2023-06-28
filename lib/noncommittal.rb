require "noncommittal/version"

module Noncommittal
  def self.start!(tables: nil, exclude_tables: [])
    raise "noncommittal is only designed to be run in your test environment!" unless Rails.env.test?

    tables ||= __gather_default_tables
    tables = tables.map(&:to_s) - exclude_tables.map(&:to_s)

    table_id_types = tables.map do |table|
      id_column = ActiveRecord::Base.connection.columns(table).find { |col| col.name == 'id' }
      id_column ? [table, id_column.sql_type] : nil
    end.compact.to_h

    ActiveRecord::Base.connection.execute <<~SQL
      #{table_id_types.map { |table_name, id_type|
        constraint_name = "constrain_noncommittal_#{table_name}"
        <<~SQL
          create table if not exists noncommittal_no_rows_allowed_#{table_name} (id #{id_type} unique);
          alter table #{table_name} drop constraint if exists #{constraint_name};
          alter table #{table_name} add constraint #{constraint_name} foreign key (id) references noncommittal_no_rows_allowed_#{table_name} (id) deferrable initially deferred;
        SQL
      }.join("\n")}
    SQL
  end

  def self.stop!(tables: nil, exclude_tables: [])
    tables ||= __gather_default_tables
    tables = tables.map(&:to_s) - exclude_tables.map(&:to_s)

    ActiveRecord::Base.connection.execute <<~SQL
      #{tables.map { |table_name|
        "alter table #{table_name} drop constraint if exists noncommittal_#{table_name};"
      }.join("\n")}
      drop table if exists noncommittal_no_rows_allowed;
    SQL
  end

  def self.__gather_default_tables
    ActiveRecord::Base.connection.select_values(
      "select table_name from information_schema.tables where table_schema = 'public' and table_type = 'BASE TABLE' and table_catalog = $1",
      "SQL",
      [ActiveRecord::Relation::QueryAttribute.new("catalog_name", ActiveRecord::Base.connection.current_database, ActiveRecord::Type::String.new)]
    ) - ["ar_internal_metadata", "schema_migrations"]
  end
end
