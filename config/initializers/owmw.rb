# Loads OWMW constats

OWMW = YAML.load_file(File.join(Rails.root, "config", "owmw.yml"))[RAILS_ENV]

