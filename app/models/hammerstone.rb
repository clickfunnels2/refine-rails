module Hammerstone
  def stabilizer_class(class_name)
    byebug
    my_class_name = if ENV['NAMESPACE_REFINE_STABILIZERS']
                      'Hammerstone::Refine::' + class_name
                    else
                      class_name
                    end

    my_class_name.constantize
  end
  module_function :stabilizer_class
end
