require 'xcodeproj'

project_path = 'Aura Health.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Add the Resources group if it doesn't exist
group = project.main_group.find_subpath('Aura Health/Resources', true)
group.set_source_tree('<group>')
group.set_path('Aura Health/Resources')

# Add the file reference
file_path = 'Aura Health/Resources/health_tips.json'
file_ref = group.find_file_by_path(file_path) || group.new_file('health_tips.json')

# Add to the copy resources build phase
resources_build_phase = target.resources_build_phase
unless resources_build_phase.files_references.include?(file_ref)
  resources_build_phase.add_file_reference(file_ref)
  puts "Added health_tips.json to the Copy Resources build phase."
else
  puts "health_tips.json is already in the Copy Resources build phase."
end

project.save
puts "Project saved successfully."
