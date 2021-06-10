module Hammerstone::Refine::Conditions::HasMeta
  def meta
    @meta ||= {}
  end

  def with_meta(value)
    meta.merge!(value)
    self
  end
end
