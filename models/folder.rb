class AudioFolder
  include Mongoid::Document
  include Mongoid::Timestamps

  default_scope ->(){ order_by( id: 'asc') }

  scope :for_user, ->(user){ where(translator: user) }

  INFOLDER = "folders"
  OUTFOLDER = 'public/audio'
  OUTTXTFOLDER = 'public/output'

  field :name, type: String
  field :duration, type: Time
  field :downloaded, type: Boolean, default: false

  belongs_to :translator, class_name: 'User'
  has_many :audio_files, dependent: :delete

  def self.import
    threads=[]
    Dir.glob("#{INFOLDER}/*.zip").each do |file|
      threads << Thread.new {
        Importer.new(file).import.tap do |imported|

          factory(imported.sanitized_name, imported.wavs.empty?).tap do |folder|
            if imported.wavs.empty?
              imported.txts.each do |tfile|
                AudioFile.upfind( Sanitize::base( tfile.first.gsub(/.txt$/, '') ), folder )
                  .txtme( File.read(tfile).strip )
              end
            else
              imported.wavs.each do |wfile|
                file = folder.digest_wav(wfile)
                AudioFile.upfind( Sanitize::base(file), folder )
                  .waveme( file )
                  .txtme( File.read("#{wfile}.txt").strip )
              end
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

  def self.factory( name, only_text = false )
    folder = unless where( name: name).exists?
        create( name: name )
     else
        where(name: name).first
     end
    unless only_text
      FileUtils.rm_rf(folder.audio_wav_folder)
      FileUtils.mkdir_p(folder.audio_wav_folder)
    end
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

  def self.total_duration
    all.map{|f| f.duration.to_i }.inject(:+)
  end

  def self.human_total_duration
    Time.at(total_duration).gmtime.strftime('%R:%S')
  end

  def self.payroll_total
    (Time.at(total_duration).gmtime.strftime('%H').to_f * 58) +
    (Time.at(total_duration).gmtime.strftime('%M').to_f * (58 / 60.0) )
  end

  def self.ganancia
    payroll_total - User.all.map(&:payroll).inject(:+)
  end

  def duration_miliseconds
    duration.to_i
  end

  def self.by_user
    User.all.map{|u| [ u.name, u.audio_folders.map(&:duration_miliseconds).inject(:+)] }
  end

  def human_duration
    duration.gmtime.strftime('%R:%S')
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
    files = AudioFile.where( audio_folder: id )
    total = files.count
    translations = files.only(:translation).where( :translation.ne => "").count
    {
      id: id.to_s,
      name: name,
      name_short: name_short,
      audios: audio_files.count,
      completed: ((translations*100)/total).to_i,
      status: files.only(:status).where( :status.ne => "new").count ==  total ? "ready" : "on_process",
      reviewed: audio_files.only(:status).where( status: "reviewed").count,
      news: audio_files.only(:status).where( status: "new").count,
      translated: translations,
      audio_files: audios.map{|a| a.prep_json(options) },
      pages: audios.total_pages,
      duration: duration.gmtime.strftime('%H:%M:%S'),
      responsable: responsable,
      hasResponsable: !responsable.nil?,
      downloaded: downloaded
    }
  end

  def status
    files = AudioFile.where( audio_folder: id )
    total = files.count
    translations = files.only(:translation).where( :translation.ne => "").count

    {
      id: id.to_s,
      name: name,
      name_short: name_short,
      completed: (total > 0) ? ((translations*100)/total).to_i : total,
      audios: total,
      status: files.only(:status).where( :status.ne => "new").count ==  total ? "ready" : "on_process",
      reviewed: files.only(:status).where( status: "reviewed").count,
      news: files.only(:status).where( status: "new").count,
      translated: translations,
      duration: duration.gmtime.strftime('%H:%M:%S'),
      responsable: responsable,
      hasResponsable: !responsable.nil?,
      downloaded: downloaded
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
    self.downloaded = true
    save
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
