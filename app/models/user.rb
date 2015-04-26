class User < ActiveRecord::Base
  has_many :authorizations
  has_many :players
  has_many :teams, through: :players

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
