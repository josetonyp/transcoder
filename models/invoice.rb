class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :audio_folders

  field :name, type: String
  field :folders_count, type: Integer

  def to_h(user)
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
end

module Accouting
  class Invoice
    def initialize(invoice, user)
      @user = user
      @invoice = invoice
      @audio_folders =  if @user
                          audio_folders.for_user(@user)
                        else
                          audio_folders
                        end
    end

    def to_h
      {
        name: name,
        created_at: created_at.strftime('%F %T'),
        folders_count: folders_count,
        translated: translated,
        reviewed: reviewed,
        folders: audio_folders_with_cost,
        total:  total
      }
    end

    def folders_count
      @audio_folders.count
    end

    def translated
      @audio_folders.translated.count * 100 / audio_folders.count
    end

    def reviewed
      @audio_folders.reviewed.count * 100 / audio_folders.count
    end

    def audio_folders_with_cost
      @audio_folders.map(&:short_h).map do |folder|
        folder.merge(amount: (cost * folder[:percent_duration]).to_f / 100)
      end
    end

    def total_cost
      (@audio_folders.sum(&:percent_duration) * cost).to_f / 100
    end

    private

    def fee
      58
    end

    def cost
      35
    end
  end

  class AdminInvoice < Invoce
    def to_h
      super.merge({
        total_amount:  total_amount,
        achieved_amount: achieved_amount,
        revenue_amount: revenue_amount,
      })
    end

    def total_amount
      @audio_folders.amount_in_money(fee)
    end

    def achieved_amount
      @audio_folders.reviewed.amount_in_money(fee)
    end

    def revenue_amount
      juju = User.where(name: 'Juju').first
      @audio_folders.for_user(juju).amount_in_money(cost) + total_amount - total_cost
    end
  end
end
