require "noncommittal/version"

module Noncommittal
  def self.start!(tables: nil, exclude_tables: [])
    raise "noncommittal is only designed to be run in your test environment!" unless Rails.env.test?

    tables ||= begin
      ActiveRecord::Base.connection.select_values(
        "select table_name from information_schema.tables where table_schema = 'public' and table_type = 'BASE TABLE' and table_catalog = $1",
        "SQL",
        [ActiveRecord::Relation::QueryAttribute.new("catalog_name", ActiveRecord::Base.connection.current_database, ActiveRecord::Type::String.new)]
      ) - ["ar_internal_metadata", "schema_migrations"]
    end
    tables = tables.map(&:to_s) - exclude_tables.map(&:to_s)

    ActiveRecord::Base.connection.execute <<~SQL
      create table if not exists noncommittal_no_rows_allowed (id bigint unique);
      #{tables.map { |table_name|
        constraint_name = "noncommittal_#{table_name}"
        <<~SQL
          alter table #{table_name} drop constraint if exists #{constraint_name};
          alter table #{table_name} add constraint #{constraint_name} foreign key (id) references noncommittal_no_rows_allowed (id) deferrable initially deferred;
        SQL
      }.join("\n")}
    SQL
  end
end
