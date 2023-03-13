# frozen_string_literal: true

require "faker"

ContactsTag.delete_all
Tag.delete_all
Contact.delete_all

print "\n  Seeding Tags "
10.times do |i|
  print "."
  Tag.create(name: "tag_#{i + 1}")
end
puts " done!\n"

print "\n  Seeding Contacts "

50.times do
  print "."

  preferences = {theme: %w[dark light].sample}
  data = {github_stars: rand(1000), username: Faker::Internet.username}

  # Use `RAND()` for MySQL and `RANDOM()` for PostgreSQL and SQLite
  tags = Tag.order(Arel.sql('RAND()')).limit(rand(0..3))

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
    tags: tags,
    created_at: Faker::Time.between(from: Time.now - 1.year, to: Time.now - 5.minutes)
  )
end

puts " done!\n"
