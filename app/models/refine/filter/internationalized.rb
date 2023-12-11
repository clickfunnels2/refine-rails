module Refine::Filter::Internationalized
  extend ActiveSupport::Concern

  included do
    class_attribute :i18n_scope, instance_writer: false
  end

  class_methods do
    def inherited(klass)
      klass.i18n_scope = klass.model_name.pluralize.underscore.tr("/", ".")
      super
    end
  end

  private

  def heading(field)
    t("#{field}.heading")
  end

  def options_for(field)
    t("#{field}.options").map { {id: _1.to_s, display: _2} }
  end

  def t(key, **options)
    I18n.t("#{i18n_scope}.fields.#{key}", **options)
  end
end
