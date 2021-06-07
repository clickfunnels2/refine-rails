def convert(string)
  # MySQL-specific SQL conversions.
  # string.gsub("\"", "`").gsub("59:59.999999", "59:59")
  string.tr("\"", "`")
end
