require 'xcodeproj'

project_path = 'Aura Health.xcodeproj'
project = Xcodeproj::Project.open(project_path)

app_target = project.targets.find { |t| t.name == 'Aura Health' }

# Look for the file in existing references, or create it at the project level
file_ref = project.files.find { |f| f.path == 'Aura Health/Views/ProGlassPreviewWidget.swift' }
unless file_ref
  file_ref = project.new_file('Aura Health/Views/ProGlassPreviewWidget.swift')
end

# Add to app target
unless app_target.source_build_phase.files_references.include?(file_ref)
  app_target.source_build_phase.add_file_reference(file_ref)
end

project.save
puts "Added ProGlassPreviewWidget.swift to Xcode project targets."
