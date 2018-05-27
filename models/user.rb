class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :email, type: String
  field :token, type: String
  field :admin, type: Boolean, default: false

  def audio_folders
     AudioFolder.where( translator: self )
  end

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

  def payroll
    return 0 if AudioFile.where( translator: self).count() == 0
    min = admin? ? 58 : 35
    time = AudioFile.where( translator: self, status: "translated" ).sum(:duration)
    Time.at(time).gmtime.strftime('%M').to_f * (min.to_f / 60.0) + min.to_f * Time.at(time).gmtime.strftime('%H').to_f
  end

  include ::Users::Serialisable

end

