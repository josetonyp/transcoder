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

  def prep_json
    translated = audio_folders.inject(0){|t,folder| t + folder.audio_files.translated.count }
    total = audio_folders.inject(0){|t,folder| t + folder.audio_files.count }
    folders =
    {
      id: id.to_s,
      name: name,
      admin: admin,
      email: email,
      token: token,
      audios:{
        translated: translated,
        total: total,
        completed: (translated > 0) ? ((translated*100)/total).to_i : 0
      },
      folders: audio_folders.for_user(self).count(),
      payrol: ""
    }
  end

  def min_json
    {
      id: id.to_s,
      name: name,
      admin: admin
    }
  end

  def to_json
    prep_json.to_json
  end

end

