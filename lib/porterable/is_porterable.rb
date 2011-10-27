module Porterable
  module IsPorterable
    def self.included(klass)
      klass.extend MacroMethods
    end

    module MacroMethods
      def is_porterable(options = {})
        @template_class       = options[:template] || nil
        @export_find_options  = options[:find] || nil
        @exclude_columns      = options[:exclude] || []
        if options[:export] && options[:export].is_a?(Proc)
          @export_proc          = options[:export]
          @export_methods       = []
        else
          @export_methods       = options[:export] || []
        end
        @include_associations = options[:include] || []
        @unique_field         = options[:unique] || self.primary_key

        # add name and remove id for included associations
        @include_associations.each do |association|
          @exclude_columns << "#{association}_id".to_sym
          @export_methods << "#{association}_name".to_sym
        end

        extend Porterable::IsPorterable::ClassMethods
        include Porterable::IsPorterable::InstanceMethods
        extend Porterable::IsPorterable::AsyncExportMethods if options[:async]
      end

    end

    module ClassMethods
      attr_accessor :exclude_columns, :export_methods, :export_proc, :unique_field, :include_associations

      def porterable_column_names
        template_class ? template_class.column_names : self.column_names
      end

      def to_csv(options = {}, &block)
        find_options = options[:find] || export_find_options || {}
        not_columns = self.exclude_columns
        csv_data = CSV.generate(:encoding => "UTF-8") do |csv|
          columns = self.porterable_column_names
          columns.reject! {|c| not_columns.include?(c.to_sym) }
          proc_methods = self.export_proc ? self.export_proc.call(self) : []
          self.export_methods = self.export_methods | proc_methods
          columns_names = columns | self.export_methods
          csv << columns_names.compact.collect {|c| c.to_s }
          records = self.find(:all, find_options)
          total_rows = records.length
          count = 0
          records.each do |row|
            yield(count, total_rows) if block_given?
            column_values = columns.collect {|c| row.value_for_column(c) }
            self.export_methods.each do |meth|
              column_values << row.send(meth)
            end
            csv << column_values
            count += 1
          end
        end
        csv_data
      end

      def to_csv_file(filename, options = {}, &block)
        csv_data = to_csv(options) do |count, total_rows|
          pct = (count.to_f / total_rows.to_f) * 100.0
          logger.info "Exported row #{count}/#{total_rows} - #{pct}%"
          yield(count, total_rows) if block_given?
        end
        temp_file = Tempfile.new("#{rand Time.now.to_i}-#{rand(1000)}--")
        temp_file.close
        temp_path = temp_file.path
        File.open(temp_path, 'w') {|f| f << csv_data }
        FileUtils.mkdir_p(File.dirname(filename))
        FileUtils.mv(temp_path, filename)
      end

      def load_csv_str(data)
        CSV.parse(data, :headers => true, :skip_blanks => true)   # CSV returns an array of arrays
      end

      def update_from_csv(data, only_before = Time.now, test_run = false, reconcile = true, &block)
        port = {}
        csv_data = self.load_csv_str(data)
        # partition to new rows and old rows
        new_rows, old_rows = csv_data.partition {|row| row[self.unique_field].nil? }
        # update and delete
        logger.info "** only_before value = #{only_before}"
        db = self.all
        logger.info "** db rows count = #{db.size}"
        logger.info "** CSV rows count = #{csv_data.size}"
        port[:data] = data
        port[:rows_updated] = 0
        port[:rows_deleted] = 0
        port[:rows_added]   = 0
        total_rows = db.length + new_rows.length
        count = 0
        yield(count, total_rows) if block_given?
        old_rows = old_rows.inject({}) { |h,row| h.merge({row[self.unique_field].to_s => row})}
        db.each do |contact|
          if updated_row = old_rows.delete(contact.send(self.unique_field).to_s)
            if template_class
              template_class.translate_in(contact, updated_row)
            else
              contact.attributes = updated_row
            end
            contact.save(:validate => false) unless test_run
            port[:rows_updated] += 1
          else
            if reconcile
              contact.destroy unless test_run
              port[:rows_deleted] += 1
            end
          end
          count += 1
          yield(count, total_rows) if block_given?
          contact = nil
          updated_row = nil
        end
        new_rows += old_rows
        logger.warn("NEWROWS #{new_rows.size}")
        new_rows.each do |row|
          #create new rows
          #new rows should update the row user from the db
          new_contact = template_class ? template_class.translate_in(self,row) : self.new(row)
          logger.warn new_contact.errors unless new_contact.valid?
          new_contact.save(:validate => false) unless test_run
          port[:rows_added] += 1
          count += 1
          new_contact = nil
          loaded_contact = nil
          yield(count, total_rows) if block_given?
        end
        logger.warn("processed #{count}")
        port
      end

      def unique_field
        @unique_field || self.primary_key
      end

      def template_class
        case @template_class
        when Proc
          self.instance_eval(&@template_class)
        when Symbol
          self.send(@template_class)
        else
          @template_class
        end
      end

      def export_find_options
        case @export_find_options
        when Proc
          self.instance_eval(&@export_find_options)
        when Symbol
          opts = self.send(@export_find_options)
        else
          @export_find_options
        end
      end

      unless defined?(:logger)
        def logger
          Rails.logger
        end
      end
    end

    module InstanceMethods
      def value_for_column(column_name)
        if template
          value = template.translate_out(self, column_name)
        else
          value = self[column_name]
        end
        if value.is_a?(Time)
          value.strftime('%m/%d/%Y %H:%M:%S')
        else
          value
        end
      end

      def include_associations
        self.class.include_associations || []
      end

      private
      def method_missing(method_name, *args)
        meth = method_name.to_s
        if meth =~ /\_name\=$/ && included_association_method?(meth)
          set_by_name(meth.gsub('_name=',''),args[0])
        elsif meth =~ /\_name$/ && included_association_method?(meth)
          get_by_name(meth.gsub('_name',''))
        else
          super
        end
      end

      def included_association_method?(meth_name)
        include_associations.include?(meth_name.gsub(/_name(\=)?/,'').to_sym)
      end

      def set_by_name(attribute, name)
        return unless self.class.reflections.keys.include?(attribute.to_sym)
        related = self.class.reflections[attribute.to_sym].class_name.constantize.find_by_name((name || "").downcase)
        write_attribute((attribute + '_id').to_sym,related.id) if related && related.id
      end

      def get_by_name(attribute)
        self.send(attribute.to_sym).to_s
      end

      def template
        self.class.template_class
      end
    end

    module AsyncExportMethods

      def async_export(export_filename = nil, options = {})
        export_filename ||= Porterable.export_filename(self.table_name)
        command = "#{Rails.root}/script/runner \"#{self}.to_csv_file('#{export_path(export_filename)}', #{options.inspect.gsub(/"/, '\"')})\" -e #{Rails.env} 2>&1 >> #{Rails.root}/log/async.log &"
        logger.info "** running async export with #{command}"
        system command
          export_filename
      end

      def export_path(filename)
        File.join(export_directory, filename)
      end

      def export_finished?(filename)
        File.exists?(export_path(filename))
      end

      def export_directory
        File.join(Rails.root, 'exports', self.table_name)
      end

    end

  end
end
