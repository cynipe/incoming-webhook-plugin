# vi: set ft=ruby :
Jenkins::Plugin::Specification.new do |plugin|
  plugin.name         = 'incoming-webhook'
  plugin.display_name = 'Incoming Webhook Plugin'
  plugin.description  = 'A plugin that enables any web hooks to trigger jobs'
  plugin.version      = '0.0.1'

  plugin.url = 'TBD?'
  plugin.developed_by 'cynipe', 'cynipe <cynipe@gmail.com>'
  plugin.uses_repository :github => 'cynipe/incoming-webhook-plugin'

  plugin.depends_on 'ruby-runtime', '0.12'
  plugin.depends_on 'git', '1.1.26'
end
