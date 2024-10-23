module Refine::Conditions::HasIcon
  def icon_class
    @icon_class ||= nil
  end

  def icon_template
    @icon_template ||= {}
  end

  def category_icon_class
    @category_icon_class ||= nil
  end

  def category_icon_template
    @category_icon_template ||= {}
  end

  def icon_container_class
    @icon_container_class ||= nil
  end

  def with_icon(icon_class: nil, template: {}, category_icon_class: nil, category_icon_template: {}, icon_container_class: nil)
    with_icon_class(icon_class) if icon_class.present?
    with_icon_template(template) if template.present?
    with_category_icon_class(category_icon_class) if category_icon_class.present?
    with_category_icon_template(category_icon_template) if category_icon_template.present?
    with_icon_container_class(icon_container_class) if icon_container_class.present?
    self
  end

  def with_icon_class(icon_class)
    @icon_class = icon_class
    self
  end

  def with_icon_template(template_path:, locals: {})
    @icon_template = { template_path: template_path, locals: locals }
    self
  end

  def with_category_icon_class(icon_class)
    @category_icon_class = icon_class
    self
  end

  def with_category_icon_template(template_path:, locals: {})
    @category_icon_template = { template_path: template_path, locals: locals }
    self
  end

  def with_icon_container_class(icon_container_class)
    @icon_container_class = icon_container_class
    self
  end

  def has_icon?
    icon_class.present? || !icon_template.empty?
  end

end
