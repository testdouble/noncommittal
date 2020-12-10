require "noncommittal/version"

module Noncommittal
  def self.start!(tables: nil)
    tables ||= ActiveRecord::Base.descendants.map(&:table_name).compact.uniq - ["ar_internal_metadata", "schema_migrations"]

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
