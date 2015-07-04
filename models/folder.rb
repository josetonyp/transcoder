class AudioFolder
  include Mongoid::Document
  include Mongoid::Timestamps

  default_scope ->(){ order_by( id: 'asc') }

  INFOLDER = "folders"
  OUTFOLDER = 'public/audio'
  OUTTXTFOLDER = 'public/output'

  field :name, type: String
  field :duration, type: Time

  belongs_to :translator, class_name: 'User'
  has_many :audio_files, dependent: :delete

  def self.import
    threads=[]
    Dir.glob("#{INFOLDER}/*.zip").each do |file|
      threads << Thread.new {
        Importer.new(file).import.tap do |imported|

          factory(imported.sanitized_name).tap do |folder|
            imported.wavs.each do |wfile|
              file = folder.digest_wav(wfile)
              AudioFile.upfind( Sanitize::base(file), folder )
                .waveme( file )
                .txtme( File.read("#{wfile}.txt").strip )
            end
            folder.get_duration
          end

        end.destroy
      }
    end
    threads.map(&:join)
  end

  def name_short
    name.gsub(/^.*?vices\./, "").split(".").join("-")
  end

  def self.factory( name )
    folder = unless where( name: name).exists?
        create( name: name )
     else
        where(name: name).first
     end
    FileUtils.rm_rf(folder.audio_wav_folder)
    FileUtils.mkdir_p(folder.audio_wav_folder)
    folder
  end

  def digest_wav( wav_file )
    FileUtils.cp(wav_file,audio_wav_folder)
    "#{audio_wav_folder}/#{Sanitize::base(wav_file)}"
  end

  def get_duration
    self.duration = audio_files.inject(0.0){|total,audio| total.to_f + audio.duration.to_f }
    ap duration
    save
  end


  # DONE
  def started
    audio_files.where( :translator_id.exists => true ).first
  end

  def responsable
    return nil unless translator
    translator.min_json
  end

  def prep_json( page= 1, options = {})
    audios = audio_files.paginate(page:page, per_page: 30)
    {
      id: id.to_s,
      name: name,
      audios: audio_files.count,
      status: audio_files.where( :status.ne => "translated").count > 0 ? "ready" : "on_process",
      reviewed: audio_files.where( status: "reviewed").count,
      news: audio_files.where( status: "new").count,
      translated: audio_files.where( status: "translated").count,
      audio_files: audios.map{|a| a.prep_json(options) },
      pages: audios.total_pages,
      duration: duration.gmtime.strftime('%H:%M:%S'),
      responsable: responsable
    }
  end

  def status
    files = AudioFile.where( audio_folder: id )
    total = files.count
    translated = files.only(:status).where( status: "translated").count
    {
      id: id.to_s,
      name: name,
      name_short: name_short,
      completed: ((translated*100)/total).to_i,
      audios: total,
      status: files.only(:status).where( :status.ne => "new").count ==  total ? "ready" : "on_process",
      reviewed: files.only(:status).where( status: "reviewed").count,
      news: files.only(:status).where( status: "new").count,
      translated: translated,
      duration: duration.gmtime.strftime('%H:%M:%S'),
      responsable: responsable,
      hasResponsable: !responsable.nil?
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
    File.delete(zipfile_name) if File.exists?(zipfile_name)
    FileUtils.remove_dir(audio_wav_folder) if Dir.exists?(audio_wav_folder)
    FileUtils.remove_dir("#{audio_files_folder}") if Dir.exists?("#{audio_files_folder}")
  end


  def take_by(user)
    self.translator = user
    save
    self
  end

end
