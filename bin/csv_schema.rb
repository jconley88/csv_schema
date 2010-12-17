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
    @field_requirements = args[:field_requirements] || []
    @field_requirements.each do |field, requirements|
      @unique_fields[field] = [] if requirements[:unique]
      @cant_be_nil_fields << field if requirements[:cant_be_nil]
      @restrict_value_fields[field] = requirements[:restrict_values] if requirements[:restrict_values]
    end
  end

  def validate()
    raise "#{@file} cannot be found" unless File.exists?(@file)
    header_row = true
    @current_row = 1
    FasterCSV.foreach(@file) do |row|
      if header_row
        validate_duplicate_headers(row, @headers_transform) unless @allow_duplicate_headers
        validate_blank_headers(row) unless @allow_blank_headers
        validate_required_headers(row) if @required_headers
        header_row = false
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
  def validate_duplicate_headers(row, transform = nil)
    headers = transform ? row.map{ |header| transform.call(header)} : row
    dups = headers.inject(Hash.new(0)) { |h, v| h[v] += 1; h }.reject { |k, v| v==1 }.keys #http://snippets.dzone.com/posts/show/3838
    if dups.length > 0
      raise "Duplicate headers exist: #{dups.inspect}"
    end
  end

  def validate_blank_headers(row)
    raise if row.any?{|h| (h == '') || (h == nil)}
  end

  def validate_required_headers(row)
    missing = @required_headers - row
    raise "#{File.basename(@file)} is missing headers: #{missing.inspect}" unless missing.empty?
  end

  def validate_blank_rows(row)
    raise "#{File.basename(@file)} has blank rows" if row.all?{|f| (f == nil) || (f == '')}
  end

  def validate_different_field_counts(row)
    @field_count ||= row.count
    raise "Row #{@current_row} has a different number of fields" if @field_count != row.count
  end

  def validate_restrict_value_fields(row)
    @restrict_value_fields.each do |field, allowed_values|
      raise "The '#{field}' column contains an illegal value: '#{row[field]}'" unless allowed_values.include?(row[field])
    end
  end

  def validate_cant_be_nil_fields(row)

  end

  def add_to_uniqueness_validator(row)

  end

  def validate_unique_fields
    
  end
end