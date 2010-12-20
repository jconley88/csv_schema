require 'fastercsv'

class CSVSchema
  def initialize(args)
    @file = args[:file] || raise(":file argument is required")

    @allow_duplicate_headers = (args[:allow_duplicate_headers] == nil ? false : args[:allow_duplicate_headers])
    @headers_transform = args[:headers_transform]
    @allow_blank_headers = (args[:allow_blank_headers] == nil ? false : args[:allow_blank_headers])
    @required_headers = args[:required_headers]
    @allow_blank_rows = (args[:allow_blank_rows] == nil ? false : args[:allow_blank_rows])
    @allow_different_field_counts = (args[:allow_different_field_counts] == nil ? false : args[:allow_different_field_counts])

    @unique_fields = {}
    @cant_be_nil_fields = []
    @restrict_value_fields = {}
    field_requirements = args[:field_requirements] || []
    field_requirements.each do |field, requirements|
      @unique_fields[field] = [] if requirements[:unique]
      @cant_be_nil_fields << field if requirements[:cant_be_nil]
      @restrict_value_fields[field] = requirements[:restrict_values] if requirements[:restrict_values]
    end
  end

  def validate()
    raise "#{@file} cannot be found" unless File.exists?(@file)
    @current_row = 1
    FasterCSV.foreach(@file) do |row|
      if @current_row == 1
        @headers = row
        index_field_requirements_by_column_number
        validate_duplicate_headers(row, @headers_transform) unless @allow_duplicate_headers
        validate_blank_headers(row) unless @allow_blank_headers
        validate_required_headers(row) if @required_headers
      else
        validate_blank_rows(row) unless @allow_blank_rows
        validate_restrict_value_fields(row) if !@restrict_value_fields.empty?
        validate_cant_be_nil_fields(row) if !@cant_be_nil_fields.empty?
        add_to_uniqueness_validator(row) if !@unique_fields.empty?
      end
      validate_different_field_counts(row) unless @allow_different_field_counts
      @current_row += 1
    end
    validate_unique_fields
  end

private
  def index_field_requirements_by_column_number
    headers_to_column_number = {}
    @headers.each_with_index do |header, column_number|
      headers_to_column_number[header] = column_number
    end
    @indexed_headers = headers_to_column_number.invert

    cbn = []
    @cant_be_nil_fields.each do |field|
      cbn << headers_to_column_number[field]
    end
    @cant_be_nil_fields = cbn

    rv = {}
    @restrict_value_fields.each do |field, restrict_values|
      rv[headers_to_column_number[field]] = restrict_values
    end
    @restrict_value_fields = rv

    u = {}
    @unique_fields.each do |field, unique|
      u[headers_to_column_number[field]] = unique
    end
    @unique_fields = u
  end

  def validate_duplicate_headers(row, transform = nil)
    headers = transform ? row.map{ |header| transform.call(header)} : row
    dups = headers.inject(Hash.new(0)) { |h, v| h[v] += 1; h }.reject { |k, v| v==1 }.keys #http://snippets.dzone.com/posts/show/3838
    if dups.length > 0
      raise "Duplicate headers exist: #{dups.inspect}"
    end
  end

  def validate_blank_headers(row)
    raise "There are illegal blank headers.  If this is allowed, set :allow_blank_headers => true" if row.any?{|h| (h == '') || (h == nil)}
  end

  def validate_required_headers(row)
    missing = @required_headers - row
    raise "#{File.basename(@file)} is missing headers: #{missing.inspect}" unless missing.empty?
  end

  def validate_blank_rows(row)
    raise "Row #{@current_row} in #{File.basename(@file)} is blank" if row.all?{|f| (f == nil) || (f == '')}
  end

  def validate_different_field_counts(row)
    @field_count ||= row.count
    raise "Row #{@current_row} has a different number of fields than all the rows preceding it" if @field_count != row.count
  end

  def validate_restrict_value_fields(row)
    @restrict_value_fields.each do |col_num, allowed_values|
      raise "The '#{header_name(col_num)}' column contains an illegal value: '#{row[col_num]}' in row #{@current_row}" unless allowed_values.include?(row[col_num])
    end
  end

  def validate_cant_be_nil_fields(row)
    @cant_be_nil_fields.each do |col_num|
      if row[col_num] == nil
        msg = "The '#{header_name(col_num)}' column contains an illegal nil value in row #{@current_row}"
        raise msg
      end
    end
  end

  def add_to_uniqueness_validator(row)
    @unique_fields.keys.each do |col_num|
      @unique_fields[col_num] << row[col_num]
    end
  end

  def validate_unique_fields
    @unique_fields.each do |col_num, values|
      dups    = values.inject(Hash.new(0)) { |h, v| h[v] += 1; h }.reject { |k, v| v==1 }.keys #http://snippets.dzone.com/posts/show/3838
      if dups.length > 0
        raise "The '#{header_name(col_num)}' column contains illegal duplicate values: #{dups.inspect}"
      end
    end
  end

  def header_name(col_num)
    @indexed_headers[col_num]
  end
end