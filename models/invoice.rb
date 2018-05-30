class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :audio_folders

  field :name, type: String
  field :folders_count, type: Integer

  def to_h(user=nil)
    if user
      Accouting::Invoice.new(self, user).to_h
    else
      Accouting::AdminInvoice.new(self).to_h
    end
  end

  def update_folders_count
    self.folders_count = audio_folders.count
    self.save!
  end

  def from_batch(batch)
    batch.audio_folders.each do |folder|
      self.audio_folders << folder
    end
  end
end

module Accouting
  class Invoice
    def initialize(invoice, user=nil)
      @user = user
      @invoice = invoice
      @audio_folders =  if @user
                          @invoice.audio_folders.for_user(@user)
                        else
                          @invoice.audio_folders
                        end
    end

    def to_h
      {
        name: @invoice.name,
        created_at: @invoice.created_at.strftime('%F %T'),
        folders_count: folders_count,
        translated: translated,
        reviewed: reviewed,
        folders: audio_folders_with_cost,
        total:  total_cost
      }
    end

    def folders_count
      @audio_folders.count
    end

    def translated
      return 0 if @audio_folders.count == 0
      @audio_folders.translated.count * 100 / @audio_folders.count
    end

    def reviewed
      return 0 if @audio_folders.count == 0
      @audio_folders.reviewed.count * 100 / @audio_folders.count
    end

    def audio_folders_with_cost
      @audio_folders.map(&:short_h).map do |folder|
        folder.merge(amount: (cost * folder[:duration]).to_f / 100)
      end
    end

    def total_cost
      (@audio_folders.sum(&:percent_duration) * cost).to_f / 100
    end

    protected

    def amount_in_money(query, fee)
      (query.inject(0){|acc, a| acc + a.percent_duration} * fee).to_f / 100
    end

    def fee
      58
    end

    def cost
      35
    end
  end

  class AdminInvoice < Invoice
    def to_h
      super.merge({
        total_amount:  total_amount,
        achieved_amount: achieved_amount,
        revenue_amount: revenue_amount,
      })
    end

    def total_amount
      amount_in_money @audio_folders, fee
    end

    def achieved_amount
      amount_in_money @audio_folders.reviewed, fee
    end

    def revenue_amount
      juju = User.where(name: 'Juju').first
      amount_in_money(@audio_folders.for_user(juju), cost) + total_amount - total_cost
    end
  end
end
