require 'xcodeproj'

project_path = 'Aura Health.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Aura Health' }
group = project.main_group.find_subpath(File.join('Aura Health', 'ViewModels'), true)

files_to_add = [
  'Aura Health/ViewModels/MedicationStore+Profiles.swift',
  'Aura Health/ViewModels/MedicationStore+Doses.swift',
  'Aura Health/ViewModels/MedicationStore+Inventory.swift',
  'Aura Health/ViewModels/MedicationStore+Appointments.swift',
  'Aura Health/ViewModels/MedicationStore+Vitals.swift',
  'Aura Health/ViewModels/MedicationStore+Persistence.swift'
]

files_to_add.each do |file_path|
  # Ensure we don't add duplicates
  unless group.files.find { |f| f.path == File.basename(file_path) }
    file_ref = group.new_reference(File.basename(file_path))
    target.add_file_references([file_ref])
    puts "Added #{file_path}"
  end
end

project.save
puts "Project saved successfully."
