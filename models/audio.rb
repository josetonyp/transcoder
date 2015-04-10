class AudioFile
  include Mongoid::Document
  include Mongoid::Timestamps


  belongs_to :audio_folder

  default_scope order_by(:id => 'asc')

  field :name, type: String
  field :translation, type: String
  field :status, type: String, default: "new"
  field :translator, type: String
  field :file, type: String
  field :duration, type: Time

  def prep_json
    {
      id: id,
      name: name,
      translation: translation,
      status: status,
      translator: translator,
      public_file: file.gsub("public", ""),
      duration: duration.gmtime.strftime('%R:%S'),
      audio_folder: audio_folder.id
    }
  end

  def to_json
    prep_json.to_json
  end
end

class AudioFolder
  include Mongoid::Document
  include Mongoid::Timestamps

  default_scope order_by(:id => 'asc')

  INFOLDER = "folders"
  OUTFOLDER = "public/audio"

  field :name, type: String
  field :duration, type: Time
  has_many :audio_files


  def self.import
    Dir.glob( "#{INFOLDER}/*.zip" ).each do |file|
      unzip( file )
    end
  end

  def self.unzip( file )
    name = file.gsub("folders/", "").gsub(".zip", "")
    puts "Handling folder #{name}"
    folder = create( name: name )
    FileUtils.mkdir_p "#{OUTFOLDER}/#{folder.id}"
    total = 0
    Zip::File.open(file) do |zip_file|
      total = zip_file.inject(0.0) do |seconds, entry|
        # Extract to file/directory/symlink

        if entry.to_s.match(/.wav$/)
          outfile = "#{OUTFOLDER}/#{folder.id}/#{entry}"


          audio = AudioFile.create!( name: entry , audio_folder: folder, file: outfile) unless AudioFile.where(name: entry, audio_folder: folder).exists?
          puts "Extracting #{entry.name}"
          entry.extract(outfile) unless File.exists?(outfile)

          wave = WaveInfo.new(outfile)
          audio.update_attributes!( duration: Time.at(wave.duration))
          seconds + wave.duration
        else
          seconds
        end

      end
    end

    folder.update_attributes!( duration: Time.at(total))
    File.delete( file )
  end

  def prep_json( page= 1)
    puts page
    {
      id: id,
      name: name,
      audios: audio_files.count,
      status: audio_files.where( :status.ne => "translated").none? ? "ready" : "on_process",
      reviewed: audio_files.where( status: "reviewed").count,
      news: audio_files.where( status: "new").count,
      translated: audio_files.where( status: "translated").count,
      audio_files: audio_files.paginate(page:page, per_page: 30).map(&:prep_json),
      pages: audio_files.paginate(page:page, per_page: 30).total_pages,
      duration: duration.strftime('%H:%M:%S')
    }
  end

  def status
    {
      id: id,
      name: name,
      audios: audio_files.count,
      status: audio_files.where( :status.ne => "translated").none? ? "ready" : "on_process",
      reviewed: audio_files.where( status: "reviewed").count,
      news: audio_files.where( status: "new").count,
      translated: audio_files.where( status: "translated").count,
      duration: duration.strftime('%H:%M:%S'),
    }
  end

  def to_json
    prep_json.to_json
  end

  before_destroy do
    FileUtils.remove_dir("#{OUTFOLDER}/#{id}") if Dir.exists?("#{OUTFOLDER}/#{id}")
  end

end