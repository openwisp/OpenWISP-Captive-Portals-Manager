namespace :rails do
  desc "Repair permissions to allow user to perform all actions"
  task :repair_permissions, :roles => :app do
    puts "Applying correct permissions to allow for proper command execution"
    try_sudo "mkdir -p #{shared_path}/log #{current_path}/tmp #{shared_path}/system"
    try_sudo "chmod -R 770 #{shared_path}/log #{current_path}/tmp #{shared_path}/system"
    try_sudo "chown -R www-data.www-data #{shared_path}/log #{current_path}/tmp #{shared_path}/system"
  end
end
