module Refine::Conditions::HasIcon
  def icon_class
    @icon_class ||= nil
  end

  def icon_template
    @icon_template ||= {}
  end

  def with_icon_class(icon_class)
    @icon_class = icon_class
    self
  end

  def with_icon_template(template_path:, locals: {})
    @icon_template = { template_path: template_path, locals: locals }
    self
  end

  def has_icon?
    icon_class.present? || !icon_template.empty?
  end

end
