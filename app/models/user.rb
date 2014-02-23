class User < ActiveRecord::Base
  has_many :authorizations

  def self.create_with_omniauth(auth)
    user = create! do |user|
      if auth['info']
        user.name = auth['info']['name'] || ""
        user.email = auth['info']['email'] || ""
      end
    end
    user.authorizations.create!( :provider => auth['provider'], :uid => auth['uid'] ) 
    user
  end
end
