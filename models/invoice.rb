class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :audio_folders

  field :name, type: String
  field :folders_count, type: Integer
  field :cost, type: Integer, default: 35
  field :amount, type: Integer, default: 58

  def to_h(user=nil)
    if user
      Accouting::Invoice.new(self, user).to_h
    else
      Accouting::AdminInvoice.new(self).to_h
    end
  end

  def to_csv
    Accouting::AdminInvoice.new(self).to_csv
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
        id: @invoice.id.to_s,
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
    using Refinements::FloatComma
    def to_h
      super.merge({
        folders:  audio_folders_with_fee,
        total_amount:  total_amount,
        achieved_amount: achieved_amount,
        revenue_amount: revenue_amount
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

    def audio_folders_with_fee
      @audio_folders.map(&:short_h).map do |folder|
        folder.merge(cost: (cost * folder[:duration]).to_f / 100)
              .merge(amount: (fee * folder[:duration]).to_f / 100)
      end
    end

    def total_duration
      @audio_folders.sum(:percent_duration).to_f / 100
    end

    def to_csv
      CSV.generate(col_sep: "\t") do |csv|
        csv << ["Admin Invoice"]
        csv << ["Folder", "duration", "cost", "amount"]
        audio_folders_with_fee.each do |folder|
          csv << [folder[:name], (folder[:duration].to_f / 100).to_comma_string, folder[:cost].to_comma_string, folder[:amount].to_comma_string]
        end
        csv << ["Total", total_duration, total_cost.to_comma_string, total_amount.to_comma_string]
        csv << [""]

        User.with_folders.each do |user|
          invoice = @invoice.to_h(user)
          csv << ["#{user.name} Invoice"]
          csv << ["Folder", "amount"]
          invoice[:folders].each do |folder|
            csv << [folder[:name], folder[:amount].to_comma_string]
          end
          csv << ["Total", invoice[:total].to_comma_string]
          csv << [""]
        end
      end
    end
  end
end
