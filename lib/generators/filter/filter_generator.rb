# frozen_string_literal: true

# Generates a filter for a given model.
class FilterGenerator < Rails::Generators::NamedBase
  CONDITIONS = %w[text date numeric].freeze
  source_root File.expand_path('templates', __dir__)

  def create_filter
    @conditions = extract_conditions(args)
    template 'filter.rb.erb', "app/filters/#{plural_name}_filter.rb"
  end

  private

  def extract_conditions(args)
    conditions = []
    args.each do |arg|
      field, condition = arg.split(':')

      throw "#{condition} is an invalid condition" unless CONDITIONS.include? condition

      conditions << { field: field, condition: condition.capitalize }
    end

    conditions
  end
end
