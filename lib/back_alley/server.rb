require 'json'
require 'lwes'
require 'sinatra/base'

module BackAlley
  class Server < Sinatra::Base
    use BackAlley::BodyParser

    mime_type :json, 'application/json'
    mime_type :xml,  'text/xml'
    mime_type :plist, 'application/x-plist'

    configure do
      set :views,  File.dirname(__FILE__) + '/views'
      set :raise_errors, false
      set :show_exceptions, false
    end

    error do
      e = request.env['sinatra.error']
      error_hash = get_error_hash(e)
      restful(error_hash, error_hash[:code])
    end

    helpers do
      def lwes
        params[:lwes]
      end

      def get_error_hash(e)
        { :code => (e.respond_to?(:code) ? e.code : 500), 
          :status => (e.respond_to?(:status) ? e.status : "Internal Server Error"), 
          :description => e.to_s, 
          :stacktrace => e.backtrace.join("\n"), 
          :params => params,
          :content_type => content_type 
        }
      end

      def restful(hash, code=200)
        output = case content_type
        when mime_types(:json)
          content_type(:json)
          hash.to_json
        when mime_types(:xml)
          content_type(:xml)
          hash.to_xml
        when mime_types(:plist)
          content_type(:plist)
          hash.to_plist
        else
          hash.to_json # defaults to json
        end

        [code, output]
      end

      def emitter_for(str_or_hash)
        if str_or_hash.is_a? Hash
          opt = str_or_hash
        else
          temp = str_or_hash.to_s.split(":")
          opt = { :host => temp[0].to_s.strip, :port => (temp[1] || 12345).to_s.strip.to_i }
        end

        key = "#{opt[:host]}:#{opt[:port]}"

        @emitters ||= {}
        @emitters[key] ||= Lwes::Emitter.new(opt)
      end

      def transform_event_hash(hash)
        result = {}
        result[:name] = hash[:name]

        result[:attributes] = hash[:attributes].inject({}) do |attributes, attribute|
          key = attribute[:key]
          type = attribute[:type].to_sym
          value = attribute[:value]
          attributes[key] = [type, value]
          attributes
        end

        result
      end
      
      def valid_types
        @valid_types ||= Lwes::TYPE_TO_BYTE.keys.collect{|k| k.to_s}
      end
      
      def validate_lwes
        raise ClientError, "lwes root is not specified." if lwes.nil?
        raise ClientError, "lwes must be an array containing event batches." if lwes && !lwes.is_a?(Array)
      end
      
      def validate_batch(batch)
        raise ClientError, "multicast is not specified." if batch[:multicast].nil?
        raise ClientError, "multicast must be a hash." if !batch[:multicast].is_a?(Hash)
        raise ClientError, "multicast must have host and port." batch[:multicast][:host].nil? || batch[:multicast][:port].nil?
        raise ClientError, "events must be specified." if batch[:events].nil?
        raise ClientError, "events must be an array." if !batch[:events].is_a?(Array)
      end
      
      def validate_event_hash(event)
        events.each do |e|
          raise ClientError, "event must be a hash." if !e.is_a?(Hash)
          raise ClientError, "event must contain name and attributes" if e[:name].nil? || .nil?
          raise ClientError, "event attributes must be an array" unless e[:attributes].is_a?(Array)
          validate_event_attributes(e[:attributes])
        end
      end
      
      def validate_event_attributes(attributes)
        attributes.each do |attribute|
          raise ClientError, "attribute must be a hash." if !attribute.is_a?(Hash)
          raise ClientError, "attribute must hash containing :key, :type, and :value" if a[:name].nil? || a[:type].nil? || a[:value].nil?
        end
      end
    end

    get '/lwes' do
      haml :index
    end

    post '/lwes' do
      batches = {}

      # validate raw data, construct event objects, and validate each event
      validate_lwes
      lwes.each do |batch|
        validate_batch(batch)
        emitter = emitter_for(batch[:multicast])
        batches[emitter.address] ||= {:emitter => emitter}
        batches[emitter.address][:events] ||= []
        batches[emitter.address][:events] += batch[:events].collect do |event_hash|
          validate_event_hash(event_hash)
          event = Lwes::Event.new(transform_event_hash(event_hash))
          begin
           event.validate!
          rescue Lwes::Validation::ValidationError => e
            raise ClientError, "Lwes Event Validation Failed: #{e.message}"
          end
          event
        end
      end
      
      # sending events, we assume there shouldn't be 
      batches.values.each do |batches|
        emitter = batches[:emitter]
        batch[:events].each do |event|
          begin
            emitter.emit event
          rescue Errno::EINVAL
            nil # The UDP endpoint is not up, don't do anything...
          end
        end
      end
      
      restful({:status => "Created", :code => 201}, 201)
    end
  end
end
