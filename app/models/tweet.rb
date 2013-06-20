class Tweet < ActiveRecord::Base
  belongs_to :user

  def mark_failed!
    self.failed = true
    self.save
  end

  def failed?
    self.failed
  end

end
