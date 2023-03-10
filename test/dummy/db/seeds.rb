# frozen_string_literal: true

require "faker"

print "\n  Seeding Contacts ".colorize(:blue)

Contact.connection.truncate(Contact.table_name)

50.times do
  print ".".colorize(:black)

  preferences = {theme: %w[dark light].sample}
  data = {github_stars: rand(1000), username: Faker::Internet.username}
  tags = %w[tag_1 tag_2 tag_3 tag_4 tag_5].sample(rand(3))

  Contact.create(
    avatar: Faker::Avatar.image,
    active: Faker::Boolean.boolean,
    birthday: Faker::Date.birthday(min_age: 18, max_age: 65),
    last_login: Faker::Time.backward(days: 14, period: :morning),
    salary: Faker::Number.decimal(l_digits: 5, r_digits: 2),
    height: Faker::Number.decimal(l_digits: 2, r_digits: 2),
    age: Faker::Number.between(from: 18, to: 65),
    name: Faker::Name.name,
    bio: Faker::Lorem.paragraph(sentence_count: 2),
    wake_up_time: Faker::Time.between(from: Time.now - 1.day, to: Time.now, format: :short),
    preferences: preferences,
    data: data,
    tags: tags
  )
end

puts " done!\n".colorize(:blue)
