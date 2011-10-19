require "rake"

module Rake
  class Pipeline
    class Filter
      attr_accessor :input_files, :output_name, :output_root
      attr_reader :rake_tasks
      attr_writer :rake_application

      def self.processes_binary_files
        define_method(:encoding) { "BINARY" }
      end

      def encoding
        "UTF-8"
      end

      def input_files=(files)
        @input_files = files.map do |file|
          FileWrapper.new(file.root, file.path, encoding)
        end
      end

      def outputs
        hash = {}

        input_files.each do |file|
          output = output_wrapper(output_name.call(file.path))

          hash[output] ||= []
          hash[output] << file
        end

        hash
      end

      def output_files
        input_files.inject([]) do |array, file|
          array |= [output_wrapper(output_name.call(file.path))]
        end
      end

      def rake_application
        @rake_application || Rake.application
      end

      def generate_rake_tasks
        @rake_tasks = outputs.map do |output, inputs|
          dependencies = inputs.map(&:fullpath)

          dependencies.each { |path| create_file_task(path) }

          create_file_task(output.fullpath, dependencies) do
            output.create { generate_output(inputs, output) }
          end
        end
      end

    private
      def create_file_task(output, deps=[], &block)
        rake_application.define_task(Rake::FileTask, output => deps, &block)
      end

      def output_wrapper(file)
        FileWrapper.new(output_root, file, encoding)
      end
    end
  end
end
