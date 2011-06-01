# Loads OWMW constats

begin
  OWMW = YAML.load_file(File.join(Rails.root, "config", "owmw.yml"))[RAILS_ENV]
rescue
  OWMW = {}
end
