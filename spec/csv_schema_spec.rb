require 'spec'
require 'tempfile'
require 'fileutils'
require File.expand_path("bin/csv_schema")
include FileUtils

describe CSVSchema do
  before :each do
    @lenient_options = {:allow_blank_headers     => true,
                        :allow_duplicate_headers => true,
                        :allow_blank_rows        => true,
                        :allow_different_field_counts => true}
  end

  describe "initialize" do
    it "should raise if the FILE argument is not supplied" do
      lambda{CSVSchema.new()}.should raise_error
    end

    it "the ALLOW_DUPLICATE_HEADERS flag should default to false when not set" do
      csv_schema = CSVSchema.new(:file => '')
      csv_schema.instance_variable_get('@allow_duplicate_headers').should be_false
    end

    it "the ALLOW_BLANK_HEADERS flag should default to false when not set" do
      csv_schema = CSVSchema.new(:file => '')
      csv_schema.instance_variable_get('@allow_blank_headers').should be_false
    end

    it "the ALLOW_DIFFERENT_FIELDS flag should default to false when not set" do
      csv_schema = CSVSchema.new(:file => '')
      csv_schema.instance_variable_get('@allow_different_fields').should be_false
    end

    it "the ALLOW_BLANK_ROWS flag should default to false when not set" do
      csv_schema = CSVSchema.new(:file => '')
      csv_schema.instance_variable_get('@allow_blank_rows').should be_false
    end
  end

  describe ".validate" do
    before :each do
      @headers = ['header_1', 'header_2', 'header_3']
      @rows = [
        ['value_1', 'value_2', 'value_3']
      ]
    end

    it "should raise if an invalid FILE argument was supplied" do
      lambda { CSVSchema.new(@lenient_options.merge(:file => '')).validate}.should raise_error
    end

    describe "duplicate headers" do
      it "should raise when duplicate headers exist and the ALLOW_DUPLICATE_HEADERS flag is FALSE" do
        @headers = ['header_1', 'header_1']
        lambda{CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_duplicate_headers => false)).validate}.should raise_error(StandardError, /header_1/)
      end

      it "should raise when duplicate headers exist according to the HEADERS_TRANSFORM proc and the ALLOW_DUPLICATE_HEADERS flag is FALSE" do
        @headers = ['header_1', 'HEADER 1']
        transform = FasterCSV::HeaderConverters[:symbol]
        lambda{CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_duplicate_headers => false, :headers_transform => transform)).validate}.should raise_error
      end

      it "should NOT raise when NO duplicate headers exist and the ALLOW_DUPLICATE_HEADERS flag is FALSE" do
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_duplicate_headers => false)).validate}.should_not raise_error
      end

      it "should NOT raise when duplicate headers exist and the ALLOW_DUPLICATE_HEADERS flag is TRUE" do
        @headers = ['header_1', 'header_1']
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_duplicate_headers => true)).validate}.should_not raise_error
      end
    end

    describe "blank_headers" do
      it "should NOT raise when there are NO blank headers and the ALLOW_BLANK_HEADERS flag is true" do
        lambda {CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_blank_headers => true)).validate}.should_not raise_error
      end

      it "should NOT raise when there are blank headers and the ALLOW_BLANK_HEADERS flag is true" do
        @headers = ['header_1', '', 'header_2']
        lambda {CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_blank_headers => true)).validate}.should_not raise_error
      end

      it "should NOT raise when there are NO blank headers and the ALLOW_BLANK_HEADERS flag is false" do
        lambda {CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_blank_headers => false)).validate}.should_not raise_error
      end

      it "should raise when there are blank headers and the ALLOW_BLANK_HEADERS flag is false" do
        @headers = ['header_1', '', 'header_2']
        lambda {CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_blank_headers => false)).validate}.should raise_error
      end
    end

    describe "required_headers" do
      it "should NOT raise when all REQUIRED HEADERS exist" do
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :required_headers => ['header_1'])).validate }.should_not raise_error
      end

      it "should raise when any REQUIRED HEADERS do NOT exist" do
        missing_header = 'doesnt_exist'
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :required_headers => [missing_header])).validate }.should raise_error(StandardError, /#{missing_header}/)
      end
    end
    
    describe "allow_blank_rows" do
      it "should NOT raise when there are NO blank rows and the ALLOW_BLANK_ROWS flag is true" do
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_blank_rows => true)).validate }.should_not raise_error
      end

      it "should NOT raise when there are blank rows and the ALLOW_BLANK_ROWS flag is true" do
        @rows << ['', '', '']
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_blank_rows => true)).validate }.should_not raise_error
      end

      it "should NOT raise when there are NO blank rows and the ALLOW_BLANK_ROWS flag is false" do
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_blank_rows => false)).validate }.should_not raise_error
      end

      it "should raise when there are blank rows and the ALLOW_BLANK_ROWS flag is false" do
        @rows << ['', '', '']
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_blank_rows => false)).validate }.should raise_error(StandardError, /3/)
      end
    end

    describe "allow_different_field_counts" do
      it "should NOT raise when all field counts are the same and the ALLOW_DIFFERENT_FIELD_COUNTS flag is true" do
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_different_field_counts => true)).validate }.should_not raise_error
      end

      it "should NOT raise when the field count in a header row differs from a data row and the ALLOW_DIFFERENT_FIELD_COUNTS flag is true" do
        @headers << 'header_4'
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_different_field_counts => true)).validate }.should_not raise_error
      end

      it "should NOT raise when the field counts in two data rows differ and the ALLOW_DIFFERENT_FIELD_COUNTS flag is true" do
        @rows << (@rows.first << 'value_4')
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_different_field_counts => true)).validate }.should_not raise_error
      end

      it "should NOT raise when all field counts are the same and the ALLOW_DIFFERENT_FIELD_COUNTS flag is false" do
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_different_field_counts => false)).validate }.should_not raise_error
      end

      it "should raise when the field count in a header row differs from a data row and the ALLOW_DIFFERENT_FIELD_COUNTS flag is false" do
        @headers << 'header_4'
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_different_field_counts => false)).validate }.should raise_error(StandardError, /2/)
      end

      it "should raise when the field counts in two data rows differ and the ALLOW_DIFFERENT_FIELD_COUNTS flag is false" do
        @rows << (@rows.first.dup << 'value_4')
        lambda { CSVSchema.new(@lenient_options.merge(:file => generate_csv_file.path, :allow_different_field_counts => false)).validate }.should raise_error(StandardError, /3/)
      end
    end

    describe "field_requirements" do
      describe "restrict_values" do
        it "should NOT raise if all field values appear in the RESTRICT_VALUES array for the specified field" do
          options = {:file => generate_csv_file.path, :field_requirements => {'header_1' => {:restrict_values => ['value_1']}}}
          lambda { CSVSchema.new(@lenient_options.merge(options)).validate }.should_not raise_error
        end

        it "should raise if any field values do NOT appear in the RESTRICT_VALUES array for the specified field" do
          options = {:file => generate_csv_file.path, :field_requirements => {'header_1' => {:restrict_values => []}}}
          lambda { CSVSchema.new(@lenient_options.merge(options)).validate }.should raise_error(StandardError, /header_1.*value_1.*2/)
        end
      end

      describe "cant_be_nil" do
        it "should NOT raise if all values for the specified field are populated" do
          options = {:file => generate_csv_file.path, :field_requirements => {'header_1' => {:cant_be_nil => true}}}
          lambda { CSVSchema.new(@lenient_options.merge(options)).validate }.should_not raise_error
        end

        it "should NOT raise if values in fields other than the specified one have nil values" do
          @rows << ['value_1', nil, '']
          options = {:file => generate_csv_file.path, :field_requirements => {'header_1' => {:cant_be_nil => true}}}
          lambda { CSVSchema.new(@lenient_options.merge(options)).validate }.should_not raise_error
        end

        it "should raise with field name and column number if a value in the specified field is nil" do
          @rows << ['', 'value_2', 'value_3']
          options = {:file => generate_csv_file.path, :field_requirements => {'header_1' => {:cant_be_nil => true}}}
          lambda { CSVSchema.new(@lenient_options.merge(options)).validate }.should raise_error(StandardError, /header_1.*3/)
        end
      end
    end
  end
end

def generate_csv_file()
  csv_file = Tempfile.new('example_csv', File.expand_path('spec/tmp'))
  csv_file << @headers.join(',') + "\n"
  @rows.each do |row|
    csv_file << row.join(',') + "\n"
  end
  csv_file.open
end