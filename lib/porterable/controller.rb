module Porterable
  module Controller

    def self.included(other_mod)
      klass_name = other_mod.to_s.gsub(/Admin::|Controller/,'').singularize
      klass = klass_name.constantize
      port_klass = "#{klass_name}Port".constantize


      other_mod.module_eval <<-EOT
      helper_method :controller_name

      def ports
        @ports = #{port_klass}.paginate :order => "created_at DESC", :page => params[:page]
        render :template => 'shared/ports'
      end

      def import
        @port = #{port_klass}.new
        render :template => 'shared/import'
      end

      def scan
        if request.post?
          @reconcile = params[:import_type].to_i == 1 ? true : false 
          csv_data = params[:import][:file_data].read.force_encoding("ISO-8859-1")
          @port = #{port_klass}.load_csv(csv_data, @reconcile)
        else
          @reconcile = params[:import_type].to_i == 1 ? true : false 
          @port = #{port_klass}.find(params[:id])
        end
        render :template => 'shared/scan'
      end

      def execute
        redirect_to :action => 'import' and return unless request.post?
        @port = #{port_klass}.find(params[:id])
        @port = @port.import(params[:reconcile].to_i == 1 ? true : false )
        flash[:message] = 'File Import Successful.'
        redirect_to :action => 'ports'
      end

      def export
        send_data(#{port_klass}.export, :type => #{port_klass}.content_type(request.user_agent),:filename => #{port_klass}.export_filename)
      end

      EOT
    end

  end
end
