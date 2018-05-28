require 'spec_helper'

describe AudioFile do
  let(:user){ User.create(name: "Someone", email: 'somebody@somebody.com', admin: false)}
  let(:admin_user){ User.create(name: "Admin", email: 'admin@somebody.com', admin: true)}
  let(:audio_folder) { Fixtures.new_audio_folder }
  let(:audio_file) { audio_folder.audio_files.last }

  it 'set translation by given user' do
    expect(audio_file.status).to eq('created')
    expect(audio_file.translation).to eq(nil)
    audio_file.translated_by(user: user, translation: "buuuu")

    expect(audio_file.translator).to eq(user)
    expect(audio_file.translation).to eq("buuuu")
    expect(audio_file.status).to eq('translated')
    expect(audio_file.status_changes.count).to eq(1)
    expect(audio_file.status_changes.last.from).to eq("created")
    expect(audio_file.status_changes.last.to).to eq("translated")

    audio_file.translated_by(user: user, translation: "maaa")
    expect(audio_file.translation).to eq("maaa")
    expect(audio_file.status).to eq('translated')
    expect(audio_file.status_changes.count).to eq(1)
  end

  it 'sets review by given user' do
    audio_file.translated_by(user: user, translation: "buuuu")
    audio_file.reviewed_by(user: admin_user)

    expect(audio_file.translation).to eq("buuuu")
    expect(audio_file.translator).to eq(user)
    expect(audio_file.reviewer).to eq(admin_user)
    expect(audio_file.status).to eq('reviewed')
    expect(audio_file.status_changes.count).to eq(2)
  end

end
