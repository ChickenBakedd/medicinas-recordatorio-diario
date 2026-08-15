require 'xcodeproj'

project_path = 'Aura Health.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Path to the file
file_path = 'Aura Health/Managers/KeychainHelper.swift'

# Find the group
group = project.main_group.find_subpath(File.dirname(file_path), true)

# Add file reference to the group
file_reference = group.new_reference(File.basename(file_path))

# Add the file reference to all targets that need it
project.targets.each do |target|
    if target.name == 'Aura Health' || target.name == 'AuraWidgetsExtension'
        target.add_file_references([file_reference])
    end
end

project.save
