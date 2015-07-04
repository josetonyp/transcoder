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
