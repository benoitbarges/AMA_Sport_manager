class User < ApplicationRecord
  has_one_attached :avatar
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :earnings, dependent: :destroy
  has_many :expenses, dependent: :destroy
  # has_many :tournaments, through: :earnings
  # has_many :tournaments, through: :expenses
  validates :first_name, :last_name, presence: true

  attr_accessor :expense_amount

  accepts_nested_attributes_for :expenses, reject_if: :all_blank

  def tournaments
    Tournament.where id: tournament_ids
  end

  def total_earnings
    return 0 if earnings.empty?
    earnings.where('date >= ?', 12.months.ago).pluck(:real_amount).sum
  end

  def total_expenses
    return 0 if expenses.empty?
    expenses.where('date >= ?', 12.months.ago).pluck(:amount).sum
  end

  private

  def tournament_ids
    [
      earnings.pluck(:tournament_id) +
      expenses.pluck(:tournament_id)
    ].flatten.compact.uniq
  end
end
