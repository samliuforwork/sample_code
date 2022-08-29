class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :record, polymorphic: true
  has_one_attached :image

  validates :content, :user_id, :record_id, presence: true
end
