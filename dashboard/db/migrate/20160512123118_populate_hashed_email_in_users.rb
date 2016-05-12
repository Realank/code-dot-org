# A migration that populates (if not already populated) a user's hashed_email
# for users having an (non-empty) email address.

class PopulateHashedEmailInUsers < ActiveRecord::Migration
  def up
    User.with_deleted.
        where('email IS NOT NULL AND email <> ""').
        where('hashed_email IS NULL OR hashed_email = ""').
        find_each do |user|
      user.hash_email
      user.save!
    end
  end

  def down
  end
end
