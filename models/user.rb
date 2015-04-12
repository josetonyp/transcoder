class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :email, type: String
  field :token, type: String
  field :admin, type: Boolean, default: false

  include BCrypt
  field :password_hash, type: String
  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def self.auth_user(username, password)
    user = where(name: username).first
    return user if user && user.password == password
    return nil
  end

  def prep_json
    {
      name: name,
      admin: admin,
      email: email,
      token: token,
      audios:{
        translated:  AudioFile.where( translator: self, status: "translated" ).count,
        reviewed:  AudioFile.where( translator: self, status: "reviewed" ).count,
        total_time: Time.at(AudioFile.where( translator: self).sum(:duration)).gmtime.strftime('%R:%S')
      }
    }
  end

  def to_json
    prep_json.to_json
  end

end

