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

  index({ id: 1 }, {  name: "id_index" })
  index({ name: 1 }, { unique: true, name: "name_index" })
  index({ audio_folder: 1 }, { name: "audio_folder_index" })
  index({ status: 1 }, { name: "status_index" })
  index({ audio_folder: 1, status: 1 }, { name: "audio_folder_status_index" })
  index({ audio_folder: 1, status: 1, id: 1 }, { name: "id_audio_folder_status_index" })

  def prep_json(options={})
    {
      id: id.to_s,
      name: name,
      translation: translation,
      status: status,
      translator: translator,
      public_file: file.gsub('/public', ''),
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

  def self.upfind( name, folder )
    if where( name: name, audio_folder: folder ).exists?
      where( name: name, audio_folder: folder ).first
    else
      create!( name: name, audio_folder: folder )
    end
  end

  def waveme( outfile )
    wave = WaveInfo.new(outfile)
    update_attributes!( file: "/#{outfile}", duration: wave.duration )
    self
  end

  def txtme( text )
    update_attributes!( translation: text )
    self
  end

end

module Sanitize
  def self.base(name)
    name.gsub(/\s{2,}/, " ").gsub(/\s/, "_").match(/[^\/]*?$/).to_s
  end
  def self.zip( name )
    base(name.gsub(".zip", ""))
  end
  def self.txt( name )
    base(name.gsub(".txt", ""))
  end
end

class Importer

  include FileUtils

  def initialize(path)
    @path = path
    @extract_foder = "#{APPROOT}/folders"
  end

  def import
    destroy
    system "unzip -q #{@path} -d #{dest_folder}"
    delete
    self
  end

  def balanced?
    wavs.count == txts.count
  end

  def wavs
    Dir.glob("#{dest_folder}/*.wav")
  end

  def txts
    Dir.glob("#{dest_folder}/*.txt")
  end

  def sanitized_name
    Sanitize::zip @path
  end

  def destroy
    rm_rf(dest_folder) if Dir.exists?(dest_folder)
  end

  private

  def delete
    rm(@path)
  end



  def dest_folder
    "#{@extract_foder}/#{sanitized_name}"
  end


end

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
    return translator if translator
    if !translator && audio_files.where( :status => "translated").count > 0
      self.translator = User.find( audio_files
          .only(:translator)
          .group_by(&:translator_id)
          .inject({}){|m,pair| t,f = pair ;  m[t] = f.size if t ; m  }
          .max_by(&:second)
          .first)
      save
    end
    translator
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
    {
      id: id.to_s,
      name: name,
      audios: files.count,
      status: files.only(:status).where( :status.ne => "translated").count > 0 ? "ready" : "on_process",
      reviewed: files.only(:status).where( status: "reviewed").count,
      news: files.only(:status).where( status: "new").count,
      translated: files.only(:status).where( status: "translated").count,
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
    File.delete(zipfile_name) if File.exists?(zipfile_name)
    FileUtils.remove_dir(audio_wav_folder) if Dir.exists?(audio_wav_folder)
    FileUtils.remove_dir("#{audio_files_folder}") if Dir.exists?("#{audio_files_folder}")
  end

end
