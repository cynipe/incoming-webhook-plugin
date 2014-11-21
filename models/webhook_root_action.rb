# coding: utf-8
require 'jenkins/rack'

require_relative 'unprotected_root_action'
require_relative 'api'

include Java
java_import Java.java.util.logging.Logger

class WebHookRootAction < Jenkins::Model::UnprotectedRootAction
  include Jenkins::RackSupport

  display_name 'Incoming Web Hook'
  icon nil # we don't need the link in the main navigation
  url_path 'webhook'

  LOG = Logger.getLogger(WebHookRootAction.class.name)
  def call(env)
    WebHook::Api.new.call(env)
  end

end

Jenkins::Plugin.instance.register_extension(WebHookRootAction.new)
