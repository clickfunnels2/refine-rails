# desc "Explaining what the task does"
# task :refine_rails do
#   # Task goes here
# end
# Task to add refine-rails to linked gem in customer. They need to run this. 

task :refine_link_gem do 
	target = `bundle show refine-rails`.chomp
	if target.present?
	  puts "Linking refine-rails to '#{target}'."
	  `ln -s refine-rails tmp/gems/#{linked_gem}`
	end
end
