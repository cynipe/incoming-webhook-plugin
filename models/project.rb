# coding: utf-8
require 'forwardable'

include Java

java_import Java.hudson.security.ACL
java_import Java.org.acegisecurity.Authentication
java_import Java.org.acegisecurity.context.SecurityContextHolder

java_import Java.hudson.model.ParametersDefinitionProperty
java_import Java.hudson.model.StringParameterDefinition
java_import Java.hudson.model.StringParameterValue
java_import Java.hudson.model.Cause
java_import Java.hudson.model.ParametersAction
java_import Java.hudson.model.AbstractProject


module WebHook
  class Project
    extend Forwardable

    def_delegators :@jenkins_project,
                   :fullName,
                   :isParameterized,
                   :isBuildable,
                   :scheduleBuild,
                   :getProperty,
                   :getQuietPeriod

    alias_method :name, :fullName
    alias_method :to_s, :fullName
    alias_method :parametrized?, :isParameterized
    alias_method :buildable?, :isBuildable

    class << self
      def all
        with_system_priviledges do
          Java.jenkins.model.Jenkins.instance.getAllItems(AbstractProject.java_class).map do |jenkins_project|
            Project.new(jenkins_project)
          end
        end
      end

      def find(name)
        all.find {|pj| pj.name == name } or raise WebHook::ProjectNotFound
      end

      def with_system_priviledges(&block)
        ctx = SecurityContextHolder.getContext()
        old_priv = ctx.getAuthentication()
        ctx.setAuthentication(ACL::SYSTEM)
        begin
          yield block
        ensure
          ctx.setAuthentication(old_priv)
        end
      end

    end

    def initialize(jenkins_project)
      raise ArgumentError, 'jenkins project is required' unless jenkins_project
      @jenkins_project = jenkins_project
    end

    def parameters
      getProperty(ParametersDefinitionProperty.java_class).getParameterDefinitions()
    end

    def build_with_matching_params(caused_host, caused_note, params)
      filled_params = parameters.reduce([]) do |mem, param|
        next mem unless param.java_kind_of? StringParameterDefinition
        next mem unless params.key? param.name
        mem << StringParameterValue.new(param.name, params[param.name])
        mem
      end
      action = ParametersAction.new(filled_params)
      cause = Cause::RemoteCause.new(caused_host, caused_note)
      scheduleBuild(getQuietPeriod(), cause, action)
    end
  end
end
