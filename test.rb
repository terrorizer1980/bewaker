# DATABASE_NAME: hackerone_test
# DATABASE_USERNAME: docker
# DATABASE_PASSWORD: docker

require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  database: 'hackerone_test',
  username: 'docker',
  password: 'docker',
  port: '5433'
)

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: :cascade do |t|
    t.string :username

    t.timestamps
  end

  create_table :posts, force: :cascade do |t|
    t.string :title
    t.text :content
    t.boolean :public
    t.integer :owner_id
    t.json :additional_data

    t.timestamps
  end
end

class Post < ActiveRecord::Base
  belongs_to :owner, class_name: 'User'
end

class User < ActiveRecord::Base
  self.primary_key = 'id'

  has_many :posts, foreign_key: :owner_id
end
