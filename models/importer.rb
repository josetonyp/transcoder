class Importer
  include FileUtils

  def initialize(path)
    @path = path
    @extract_foder = "#{APPROOT}/folders"
  end

  def unzip
    destroy_uziped_folder
    system "unzip -qj #{@path} -d #{dest_folder}"
    delete_original_file
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

  def destroy_uziped_folder
    rm_rf(dest_folder) if Dir.exists?(dest_folder)
  end

  private

  def delete_original_file
    rm(@path)
  end

  def dest_folder
    "#{@extract_foder}/#{sanitized_name}"
  end


end
