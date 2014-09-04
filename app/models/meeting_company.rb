class MeetingCompany < ActiveRecord::Base
  unloadable

  has_many :meeting_agendas
  has_many :meeting_protocols

  validates_presence_of :name, :inn, :ogrn, :kpp, :okpo, :fact_address
  validates_uniqueness_of :name, :inn, :ogrn

  attr_accessible :name, :inn, :ogrn, :kpp, :okpo, :logo, :fact_address, :phone, :fax, :email, :site

  scope :sorted, -> { order(:name) }

  def to_s
    self.name
  end
end
