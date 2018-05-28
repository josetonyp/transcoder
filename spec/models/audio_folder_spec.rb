require 'spec_helper'

describe AudioFolder do
  let(:user) { User.create(name: "Someone", email: 'somebody@somebody.com', admin: false)}
  let(:admin_user) { User.create(name: "Admin", email: 'admin@somebody.com', admin: true)}
  let(:audio_folder) { Fixtures.new_audio_folder }

  context 'state machine' do
    it 'move the folder from imported to started' do
      audio_folder.audio_files.first.translated_by(translation: "buu", user: user)
      expect(audio_folder.status).to eq('started')
      expect(audio_folder.status_changes.count).to eq(1)
    end

    it 'move the folder from started to translated' do
      audio_folder.audio_files.each do |audio_file|
        audio_file.translated_by(translation: "buu", user: user)
      end

      expect(audio_folder.status).to eq('translated')
      expect(audio_folder.status_changes.count).to eq(2)
    end

    it 'move the folder from translated to reviewed' do
      audio_folder.audio_files.each do |audio_file|
        audio_file.translated_by(translation: "buu", user: user)
      end

      expect(audio_folder.status).to eq('translated')

      audio_folder.audio_files.each do |audio_file|
        audio_file.reviewed_by(user: user)
      end

      expect(audio_folder.status).to eq('reviewed')
      expect(audio_folder.status_changes.count).to eq(3)
    end

    it 'move the folder from reviewed to downloaded' do
      audio_folder.audio_files.each do |audio_file|
        audio_file.translated_by(translation: "buu", user: user)
      end
      audio_folder.audio_files.each do |audio_file|
        audio_file.reviewed_by(user: user)
      end
      expect(audio_folder.status).to eq('reviewed')

      audio_folder.next!

      expect(audio_folder.status).to eq('downloaded')
      expect(audio_folder.status_changes.count).to eq(4)
    end

    it 'move the folder from downloaded to delivered' do
      audio_folder.audio_files.each do |audio_file|
        audio_file.translated_by(translation: "buu", user: user)
      end
      audio_folder.audio_files.each do |audio_file|
        audio_file.reviewed_by(user: user)
      end
      expect(audio_folder.status).to eq('reviewed')

      audio_folder.next!
      audio_folder.next!

      expect(audio_folder.status).to eq('delivered')
      expect(audio_folder.status_changes.count).to eq(5)
    end

    it 'move the folder from delivered to invoiced' do
      audio_folder.audio_files.each do |audio_file|
        audio_file.translated_by(translation: "buu", user: user)
      end
      audio_folder.audio_files.each do |audio_file|
        audio_file.reviewed_by(user: user)
      end
      expect(audio_folder.status).to eq('reviewed')

      audio_folder.next!
      audio_folder.next!
      audio_folder.next!

      expect(audio_folder.status).to eq('invoiced')
      expect(audio_folder.status_changes.count).to eq(6)
    end

    it 'move the folder from invoiced to paid' do
      audio_folder.audio_files.each do |audio_file|
        audio_file.translated_by(translation: "buu", user: user)
      end
      audio_folder.audio_files.each do |audio_file|
        audio_file.reviewed_by(user: user)
      end
      expect(audio_folder.status).to eq('reviewed')

      audio_folder.next!
      audio_folder.next!
      audio_folder.next!
      audio_folder.next!

      expect(audio_folder.status).to eq('paid')
      expect(audio_folder.status_changes.count).to eq(7)
    end

    it 'move the folder from paid to archived' do
      audio_folder.audio_files.each do |audio_file|
        audio_file.translated_by(translation: "buu", user: user)
      end
      audio_folder.audio_files.each do |audio_file|
        audio_file.reviewed_by(user: user)
      end
      expect(audio_folder.status).to eq('reviewed')

      audio_folder.next!
      audio_folder.next!
      audio_folder.next!
      audio_folder.next!
      audio_folder.next!

      expect(audio_folder.status).to eq('archived')
      expect(audio_folder.status_changes.count).to eq(8)
    end
  end
end
