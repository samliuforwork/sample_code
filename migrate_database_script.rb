require 'byebug'

BACKUP_TABLES = %w[active_storage_blobs active_storage_attachments activity_logs answer_comments answer_stats answers avatars bulletins certificates cities ckeditor_assets delayed_jobs devices devices_20180228 districts feedbacks followings orderings permissions permissions_roles point_records provenances questions questions_to_provenances ratings read_marks roles roles_users schools shifts subjects subscriptions system_settings tokens topics unlock_reasons users users_to_subjects].freeze

class MysqlDump
  attr_accessor :database, :config

  def initialize(database:, config:)
    @database = database
    @config = config
  end

  def to_json_file(file_name, table)
    result = `echo "select JSON_OBJECT(#{process_columns(table)}) from #{table} a INTO OUTFILE '#{file_name}'" | mysql #{database} #{config}`

    pp result
  end

  private

  def list_column_names(table)
    raw_columns = `echo 'SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA="#{database}" AND TABLE_NAME="#{table}"' | mysql #{database} #{config}`

    raw_columns.split(/\n/).drop(1)
  end

  def mysql_json_object(columns)
    columns.each_with_object([]) { |column, array| array << "'#{column}', #{column}" }.join(',')
  end

  def process_columns(table)
    json_object = mysql_json_object(list_column_names(table))
    return json_object unless %w[point_records feedbacks avatars].include?(table)

    # regex: column not surrounded by single quotes, replace with column+0 (convert enum column from string to integer)
    json_object.gsub!(/((?!'[\w\s]*[\\']*[\w\s]*)record_type(?![\w\s]*[\\']*[\w\s]*'))/, 'record_type-1')
    json_object.gsub!(/((?!'[\w\s]*[\\']*[\w\s]*)status(?![\w\s]*[\\']*[\w\s]*'))/, 'status-1')
    json_object.gsub!(/((?!'[\w\s]*[\\']*[\w\s]*)image(?![\w\s]*[\\']*[\w\s]*'))/, 'HEX(image)')

    json_object
  end
end

class PsqlRestore
  attr_accessor :database

  def initialize(database:)
    @database = database
  end

  def database_setting
    `echo "create database #{database}" | psql`
    `RAILS_ENV=production bundle exec rails db:migrate`

    # rename keyword columns
    `echo 'ALTER TABLE active_storage_blobs RENAME COLUMN key TO reserved_word_key' | psql #{database}`
    %w[permissions provenances roles].each do |table|
      `echo 'ALTER table #{table} RENAME COLUMN "desc" TO "reserved_word_desc"' | psql #{database}`
    end
  end

  def create_temporary(table)
    `echo "create table tmp_#{table}(data jsonb not null)" | psql #{database}`
  end

  def import_tmp_data(file_name, table)
    result = `cat #{file_name} | psql #{database} -c "COPY tmp_#{table} (data) FROM STDIN;"`

    pp "imported tmp_#{table} table: #{result}"
  end

  def restore_data(table)
    result = `echo 'insert into #{table}(#{columns_names(table)}) select '"#{columns_with_types(table)}"' from tmp_#{table}' | psql #{database}`

    pp "imported table #{table}: #{result}"
  end

  def column_remove_prefix(table)
    reserved_word_columns = columns_names(table).scan(/reserved_word_[a-z]{1,}/)
    return if reserved_word_columns.size.zero?

    reserved_word_columns.each do |column|
      name_without_prefix = column.gsub('reserved_word_', '')
      `echo 'ALTER TABLE #{table} RENAME COLUMN "#{column}" TO "#{name_without_prefix}"' | psql #{database}`
    end
  end

  def migrate_sequence(table)
    `echo "SELECT setval('#{table}_id_seq', (SELECT MAX(id) from #{table}), TRUE)" | psql #{database}`
  end

  def drop_temporary(table)
    `echo "drop table tmp_#{table}" | psql #{database}`
  end

  private

  def process_type(column_name, type)
    case type
    when 'integer'
      "CAST (data->>'#{column_name}' AS INTEGER)"
    when 'boolean'
      "CAST (data->>'#{column_name}' AS BOOLEAN)"
    when 'bigint'
      "CAST (data->>'#{column_name}' AS BIGINT)"
    when 'bytea'
      "CAST (data->>'#{column_name}' AS BYTEA)"
    when 'timestampwithouttimezone'
      "TO_TIMESTAMP(data->>'#{column_name}', 'YYYY-MM-DD HH24:MI:SS')"
    when 'timewithouttimezone'
      "TO_TIMESTAMP(data->>'#{column_name}', 'YYYY-MM-DD HH24:MI:SS')"
    when 'date'
      "TO_TIMESTAMP(data->>'#{column_name}', 'YYYY-MM-DD')"
    else
      "data->>'#{column_name}'"
    end
  end

  def list_column_names_array(table)
    raw_columns = `echo "select column_name,data_type from INFORMATION_SCHEMA.COLUMNS where table_name = '#{table}'" | psql #{database}`

    raw_columns.split(/\n/).drop(2).tap(&:pop)
  end

  def columns_names(table)
    raw_columns_array = list_column_names_array(table)
    raw_columns_array.sort.each_with_object([]) { |column, array| array << column.delete(' ').split('|')[0] }.join(',')
  end

  def columns_with_types(table)
    raw_columns_array = list_column_names_array(table)

    raw_columns_array.sort.each_with_object([]) do |column, array|
      column_name, type = column.delete(' ').split('|')
      array << process_type(column_name, type)
    end.join(',')
  end
end

class MigrationService
  def self.transfer!
    mysql = MysqlDump.new(database: ENV.fetch('MYSQL_DB'), config: ENV.fetch('MYSQL_CONFIG'))
    psql = PsqlRestore.new(database: ENV.fetch('PSQL_DB'))
    psql.database_setting

    BACKUP_TABLES.each do |table|
      file_name = "#{ENV.fetch('DB_FILES_PATH')}/#{Time.now.strftime('%Y-%m-%d')}_#{table}.json"

      mysql.to_json_file(file_name, table)

      psql.create_temporary(table)
      psql.import_tmp_data(file_name, table)

      psql.restore_data(table)
      psql.column_remove_prefix(table)
      psql.migrate_sequence(table)
      psql.drop_temporary(table)
    end
  end
end

MigrationService.transfer!
