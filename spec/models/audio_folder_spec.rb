require 'spec_helper'

describe AudioFolder do
  let(:user) { User.create(name: "Someone", email: 'somebody@somebody.com', admin: false)}
  let(:admin_user) { User.create(name: "Admin", email: 'admin@somebody.com', admin: true)}
  let(:audio_folder) { Fixtures.new_audio_folder }
  let(:audio_file) { audio_folder.audio_files.last }

  it 'does something' do
    binding.pry
  end
end
