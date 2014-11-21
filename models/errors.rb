# coding: utf-8

module WebHook
  class Error < StandardError

  end

  ProjectNotFound = Class.new(Error)
end
