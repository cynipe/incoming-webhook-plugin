# coding: utf-8
include Java

java_import Java.hudson.security.csrf.CrumbExclusion

require_relative 'webhook_root_action'

class WebHookCrumbExclusion < CrumbExclusion

  def process(request, response, chain)
    return false unless exclusion_path? request.getPathInfo()
    chain.doFilter(request, response)
    true
  end

  private

  def exclusion_path?(path)
    path.to_s.start_with? "/#{WebHookRootAction.url_path}/"
  end
end
Jenkins::Plugin.instance.register_extension(WebHookCrumbExclusion.new)
