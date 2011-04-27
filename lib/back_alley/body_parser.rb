require 'hashie'
require 'crack'
require 'plist'
require 'rack'

module BackAlley
  class BodyParser
    CONTENT_TYPE = 'CONTENT_TYPE'.freeze
    POST_BODY = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH = 'rack.request.form_hash'.freeze

    FORMAT_JSON  = 'application/json'.freeze
    FORMAT_XML   = 'text/xml'.freeze
    FORMAT_PLIST = 'application/x-plist'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      parse_body(env)
      @app.call(env)
    end
    
    def parse_body(env)
      body = env[POST_BODY].read
      result =  case env[CONTENT_TYPE]
                when FORMAT_JSON
                  parse_json(body)
                when FORMAT_XML
                  parse_xml(body)
                when FORMAT_PLIST
                  parse_plist(body)
                else
                  # assumes form post
                  Rack::Request.new(env).POST
                end

      env.update(FORM_HASH => Hashie::Mash.new(result), FORM_INPUT => env[POST_BODY])
    end

    def parse_json(str)
      Crack::JSON.parse(str)
    end

    def parse_xml(str)
      Crack::XML.parse(str)
    end

    def parse_plist(str)
      Plist::parse_xml(str)
    end
  end
end