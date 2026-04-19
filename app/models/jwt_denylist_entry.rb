class JwtDenylistEntry < ApplicationRecord
  self.table_name = 'jwt_denylist'
  self.primary_key = :jti

  def self.deny!(jti, exp)
    create!(jti: jti, exp: exp)
  end

  def self.denied?(jti)
    where(jti: jti).where("exp > ?", Time.current).exists?
  end

  def self.cleanup!
    where("exp < ?", Time.current).delete_all
  end
end
