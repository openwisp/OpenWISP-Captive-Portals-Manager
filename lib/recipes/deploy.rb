after 'deploy:update_code', 'deploy:symlink_db'
after 'deploy:migrate', 'deploy:seed'

namespace :deploy do
  desc "Symlinks the database.yml"
  task :symlink_db, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end

  desc "Runs seeds"
  task :seed, :roles => :db do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec rake db:seed"
  end
end
