require 'simple_form'
require 'effective_resources'
require 'effective_datatables/engine'
require 'effective_datatables/version'

module EffectiveDatatables
  mattr_accessor :authorization_method

  mattr_accessor :default_length
  mattr_accessor :html_class
  mattr_accessor :save_state
  mattr_accessor :max_cookie_size

  mattr_accessor :actions_column # A Hash
  mattr_accessor :debug

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    @_exceptions ||= [Effective::AccessDenied, (CanCan::AccessDenied if defined?(CanCan)), (Pundit::NotAuthorizedError if defined?(Pundit))].compact

    return !!authorization_method unless authorization_method.respond_to?(:call)
    controller = controller.controller if controller.respond_to?(:controller)

    begin
      !!(controller || self).instance_exec((controller || self), action, resource, &authorization_method)
    rescue *@_exceptions
      false
    end
  end

  def self.authorize!(controller, action, resource)
    raise Effective::AccessDenied.new('Access Denied', action, resource) unless authorized?(controller, action, resource)
  end

end
