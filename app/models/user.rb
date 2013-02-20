class User < ActiveRecord::Base
  attr_accessible :count, :password, :username

  validates :password, length: { maximum: 128 }, on: :create
  validates :username, presence: true, length: { maximum: 128 }, uniqueness: true

  def self.authenticate(login, pass)
    u=find(:first, :conditions=>["username = ?", login])
    return nil if u.nil?
    return u if pass==u.password
    nil
  end  
end
