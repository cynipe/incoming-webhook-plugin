# coding: utf-8
require 'sinatra/base'
require 'json'
require 'ap'

require_relative 'errors'
require_relative 'project'

include Java

java_import Java.java.util.logging.Logger
java_import Java.java.util.logging.Level
java_import Java.org.jruby.exceptions.RaiseException

module WebHook
  class Api < Sinatra::Base
    LOG = Logger.getLogger(Api.class.name)

    get '/ping' do
      'Web Hook is up and running :)'
    end

    get '/v1/:project_name' do |project_name|
      process project_name
    end
    post '/v1/:project_name' do |project_name|
      process project_name
    end

    private
    def process(project_name)
      LOG.info "/webhook/v1/#{project_name} called."
      begin
        project = Project.find(project_name)

        return "project #{project_name} found, but it's not buildable. Nothing to do.".tap do |s|
          LOG.info s
        end unless project.buildable?
        return "project #{project_name} found, but it's not parametarized. Nothing to do.".tap do |s|
          LOG.info s
        end unless project.parametrized?

        pretty_params = incoming_request.map {|k, v| "#{k}: #{v}" }

        caused_host = env['REMOTE_HOST'] || env['REMOTE_ADDR']
        project.build_with_matching_params(caused_host, 'Triggerd by Incoming WebHook', incoming_request)
        (["#{project_name} triggerd with parameters:"] + pretty_params).join('<br>').tap do |s|
          LOG.info s.gsub('<br>', "\n")
        end
      rescue WebHook::ProjectNotFound => e
        status 404
        "project #{project_name} not found, build not triggerd".tap do |s|
          LOG.info s
        end
      rescue => e
        severe = LOG.java_method(:log, [Level, java.lang.String, java.lang.Throwable])
        severe.call(Level::SEVERE, e.message, RaiseException.new(e))
        status 500
        [e.message, '', 'Stack trace:', e.backtrace].flatten.join('<br>')
      end
    end

    def incoming_request
      @incoming_request ||= {
        'HEADERS'=> headers.to_json,
        'PARAMS' => requested_params.to_json,
        'BODY'   => request.body.read.force_encoding('UTF-8'),
      }.tap do |info|
        headers.each {|k,v| info[k] = v }
        requested_params.each {|k,v| info[k] = v }
      end
    end

    def headers
      return @headers if @headers
      http_headers = request.env.select {|k, v| k.start_with?('HTTP_') }
      @headers = http_headers.inject({}) do |mem, (k, v)|
        mem[k.sub(/^HTTP_/, "").downcase.gsub(/(^|_)\w/) {|word| word.upcase }.gsub("_", "-") ] = v
        mem
      end
    end

    def requested_params
      @requested_params ||= params.dup.tap do |h|
        h.delete 'splat'
        h.delete 'captures'
        h.delete 'project_name'
      end.tap {|h| LOG.info h.to_s}
    end
  end
end
