# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

cp = CaptivePortal.new(
    :name => "test",
    :cp_interface => "tst01",
    :wan_interface => "eth0",
    :redirection_url => "https://192.168.0.1:8081/authentication?original_url=<%ORIGINAL_URL%>",
    :error_url => "https://192.168.0.1:8081/error?message=<%MESSAGE%>&original_url=<%ORIGINAL_URL%>",
    :local_http_port => 8080,
    :local_https_port => 8081
)

cp.radius_auth_server = RadiusAuthServer.create(:host => "127.0.0.1", :port => 1812, :shared_secret => "testing123")
cp.radius_acct_server = RadiusAcctServer.create(:host => "127.0.0.1", :port => 1813, :shared_secret => "testing123")
cp.save!

op = Operator.new(
    :login => "admin",
    :password => "admin",
    :password_confirmation => "admin",
    :email => "admin@adm.in"
)

op.save!