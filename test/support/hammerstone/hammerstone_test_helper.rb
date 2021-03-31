def zulu(date)
  DateTime.strptime(date, "%m/%d/%Y").utc.iso8601(3)
end