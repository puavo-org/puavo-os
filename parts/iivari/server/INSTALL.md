
1. Use Ubuntu Lucid


Install ruby


    sudo apt-get install ruby libopenssl-ruby1.8 rubygems1.8 irb


Install rubygems and bundler

    wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
    tar zxf rubygems-1.3.7.tgz
    cd rubygems-1.3.7
    sudo ruby setup.rb

Lucid ships with rubygems 1.3.6 but bundler requires at least 1.3.7.

In the `server/` directory

    sudo apt-get install libxslt-dev ruby-dev libpq-dev libmagickcore-dev libmagickwand-dev libldap2-dev libssl-dev libsasl2-dev libsqlite3-dev
    bundle install --deployment


Add database config

    cp config/database.yml.example config/database.yml


Run database migrations

    bundle exec rake db:migrate
