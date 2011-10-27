class User < ActiveRecord::Base
  ROLES = %w[admin jobseeker employer]
  belongs_to :wall
  	
  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  
  has_many :confirms
  has_many :confirmed_events, :through => :confirms, :class_name => 'Event', :foreign_key => 'user_id'#, :date.gte => Date.today 
  has_many :pendings
  has_many :pending_events, :through => :pendings, :class_name => 'Event', :foreign_key => 'user_id'#, :date.gte => Date.today 
  
  has_many :statuses
  has_many :requests
  has_many :activities
  has_many :posts
  has_many :comments
  has_many :likes # delete this
  has_many :pages
  has_many :photos # not sure to add this feature
  has_many :memberships
  has_many :groups, :through => :memberships
  #has_many :messages
  #has_many :sent_messages, :class_name => 'Message', :foreign_key => 'user_id'
  #has_many :received_messages, :class_name => 'Message', :foreign_key => 'recipient_id'
  
  validates :username, :presence => true, :uniqueness => true
  validates_format_of :username, :with => /\A[A-Za-z0-9_]+\z/
  validates_length_of :username, :maximum => 32
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         
   acts_as_messageable :table_name => "messages",
                       :required   => [:topic, :body],           
                       :class_name => "ActsAsMessageable::Message"           
  
  after_create :create_wall                       
  
  # Setting up accessible (or protected) attributes for the model
  attr_accessible :username, :role, :email, :password, :password_confirmation, :remember_me, :message_id
  
  # Methods to manage the user roles
  def role_symbols
    [role.to_sym]
  end
  
  def role?(current_role)
    role == current_role.to_s	
  end
  # methods to nullify the user instead of delete it
  def recv
  	# super
    Message.where(:r_hidden=>false).order("created_at DESC")
  end

  def sent
    Message.where(:s_hidden=>false).order("created_at DESC")
  end
  
  def add_friend(user)
    self.friendships.create(:friend_id => user.id)  
  end
  
  def friends2
    (inverse_friends + friends).uniq
  end  
  
  def feed
    feed = [] + activities
    friends.each do |friend|
      feed += friend.activities
    end
    return feed.sort {|x,y| y.created_at <=> x.created_at}
  end

  def possessive_pronoun
    sex.downcase == 'male' ? 'his' : 'her'
  end
  
  def pronoun
    sex.downcase == 'male' ? 'he' : 'she'
  end
  
  def create_wall
    self.wall = Wall.create
    self.save
  end
  
  def all_events
    self.confirmed_events + self.pending_events
  end

  def friend_events
    events = []
    friends.each do |friend|
      events += friend.confirmed_events
    end
    return events.sort {|x,y| y.time <=> x.time}    
  end
  
  def friend_groups
    groups = []
    friends.each do |friend|
      groups += friend.groups
    end
    groups - self.groups
  end
end
