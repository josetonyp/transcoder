class AudioFile
  include Mongoid::Document
  include Mongoid::Timestamps

  OUTFOLDER = 'public/output'

  belongs_to :audio_folder
  belongs_to :translator, class_name: 'User'
  belongs_to :reviewer, class_name: 'User'

  default_scope ->(){ order_by( id: 'asc') }

  field :name, type: String
  field :translation, type: String
  field :status, type: String, default: 'new'
  field :file, type: String
  field :duration, type: Float

  index({ name: 1 }, { unique: true, name: "name_index" })

  def prep_json(options={})
    {
      id: id.to_s,
      name: name,
      translation: translation,
      status: status,
      translator: translator,
      public_file: file.gsub('public', ''),
      duration: Time.at(duration).gmtime.strftime('%R:%S'),
      audio_folder: audio_folder.id
    }.merge!(options)
  end

  def file_name
    "#{OUTFOLDER}/#{audio_folder.id.to_s}/#{name}.txt"
  end

  def save_file
    File.delete(file_name) if File.exists?(file_name)
    File.write(file_name, translation)
  end

  def to_json
    prep_json.to_json
  end
end

class AudioFolder
  include Mongoid::Document
  include Mongoid::Timestamps

  default_scope ->(){ order_by( id: 'asc') }

  INFOLDER = 'folders'
  OUTFOLDER = 'public/audio'
  OUTTXTFOLDER = 'public/output'

  field :name, type: String
  field :duration, type: Time

  has_many :audio_files, dependent: :delete

  def self.import
    Dir.glob("#{INFOLDER}/*.zip").each do |file|
      unzip(file)
    end
  end

  def self.unzip(file)
    name = file.gsub('folders/', 'folders/').gsub(".zip", "")
    puts "Handling folder #{name}"
    folder = create( name: name )
    FileUtils.mkdir_p "#{OUTFOLDER}/#{folder.id}"
    total = 0
    Zip::File.open(file) do |zip_file|
      total = zip_file.inject(0.0) do |seconds, entry|
        # Extract to file/directory/symlink
        audio = if AudioFile.where( name: entry.to_s.gsub(".txt", "") ).exists?
                  AudioFile.where( name: entry.to_s.gsub(".txt", "") ).first
                else
                  AudioFile.create!( name: entry.to_s.gsub(".txt", "") )
                end
        if entry.to_s.match(/.wav$/)
          outfile = "#{OUTFOLDER}/#{folder.id}/#{entry}"
          audio.update_attributes(audio_folder: folder, file: outfile)
          puts "Extracting #{entry.name}"
          entry.extract(outfile) unless File.exists?(outfile)

          wave = WaveInfo.new(outfile)
          audio.update_attributes!( duration: wave.duration )
          seconds + wave.duration
        else
          audio.update_attributes(audio_folder: folder, translation: zip_file.read(entry.to_s).strip)
          seconds
        end
      end
    end

    folder.update_attributes!( duration: Time.at(total))
    File.delete( file )
  end

  def started
    audio_files.where( :translator_id.exists => true ).first
  end

  def responsable
    return unless started
    User.find( audio_files
        .only(:translator)
        .group_by(&:translator_id)
        .inject({}){|m,pair| t,f = pair ;  m[t] = f.size if t ; m  }
        .max_by(&:second)
        .first)
  end

  def prep_json( page= 1, options = {})
    puts page
    {
      id: id.to_s,
      name: name,
      audios: audio_files.count,
      status: audio_files.where( :status.ne => "translated").none? ? "ready" : "on_process",
      reviewed: audio_files.where( status: "reviewed").count,
      news: audio_files.where( status: "new").count,
      translated: audio_files.where( status: "translated").count,
      audio_files: audio_files.paginate(page:page, per_page: 30).map{|a| a.prep_json(options) },
      pages: audio_files.paginate(page:page, per_page: 30).total_pages,
      duration: duration.gmtime.strftime('%H:%M:%S'),
      responsable: responsable
    }
  end

  def status
    {
      id: id.to_s,
      name: name,
      audios: audio_files.count,
      status: audio_files.where( :status.ne => "translated").none? ? "ready" : "on_process",
      reviewed: audio_files.where( status: "reviewed").count,
      news: audio_files.where( status: "new").count,
      translated: audio_files.where( status: "translated").count,
      duration: duration.gmtime.strftime('%H:%M:%S'),
      responsable: responsable
    }
  end

  def to_json
    prep_json.to_json
  end

  def zipfile_name
    "#{OUTTXTFOLDER}/#{name.gsub(/^[^\/]*?\//, "")}.zip"
  end

  def audio_wav_folder
    "#{OUTFOLDER}/#{id}"
  end

  def audio_files_folder
    "#{OUTTXTFOLDER}/#{id}"
  end

  def prepare_to_download
    FileUtils.mkdir_p audio_files_folder
    audio_files.map(&:save_file)
  end

  def build
    prepare_to_download
    File.delete( zipfile_name ) if File.exist?( zipfile_name)

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      Dir.glob( "#{audio_files_folder}/*" ).each do |filename|
        # Two arguments:
        # - The name of the file as it will appear in the archive
        # - The original file, including the path to find it
        zipfile.add(filename.gsub("#{audio_files_folder}/",""),filename)
      end
    end
  end

  before_destroy do
    File.delete(zipfile_name)
    FileUtils.remove_dir(audio_wav_folder) if Dir.exists?(audio_wav_folder)
    FileUtils.remove_dir("#{audio_files_folder}") if Dir.exists?("#{audio_files_folder}")
  end

end