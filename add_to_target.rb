require 'xcodeproj'

project_path = 'Aura Health.xcodeproj'
project = Xcodeproj::Project.open(project_path)

widget_target = project.targets.find { |t| t.name == 'AuraWidgetsExtension' }

if !widget_target
  puts "Error: Widget target not found"
  exit 1
end

build_phase = widget_target.source_build_phase

files_to_add = [
  'MedicationModels.swift',
  'MedicationStore.swift',
  'WatchSyncManager.swift',
  'NotificationManager.swift',
  'PremiumManager.swift',
  'HapticManager.swift',
  'AttachmentManager.swift'
]

project.files.each do |file_ref|
  # Match by the last part of the path (the filename)
  name = file_ref.path ? File.basename(file_ref.path.to_s) : file_ref.name
  if name && files_to_add.include?(name)
    puts "Found #{name}"
    unless build_phase.files_references.include?(file_ref)
      puts "Adding #{name} to target"
      build_phase.add_file_reference(file_ref)
    else
      puts "#{name} is already in the target"
    end
  end
end

project.save
puts "Project saved successfully."
