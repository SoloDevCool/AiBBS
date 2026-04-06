require "net/http"
require "uri"
require "json"
require "digest/md5"

class BaiduTranslateService
  API_URL = "https://fanyi-api.baidu.com/api/trans/vip/translate"

  def self.translate(text, from: "auto", to: "en")
    new.translate(text, from: from, to: to)
  end

  def translate(text, from: "auto", to: "en")
    appid = SiteSetting.get("baidu_translate_appid")
    key = SiteSetting.get("baidu_translate_key")

    if appid.blank? || key.blank?
      Rails.logger.warn "[BaiduTranslate] APPID or KEY not configured"
      return nil
    end

    salt = SecureRandom.hex(8)
    sign = Digest::MD5.hexdigest("#{appid}#{text}#{salt}#{key}")

    uri = URI(API_URL)
    params = {
      q: text,
      from: from,
      to: to,
      appid: appid,
      salt: salt,
      sign: sign
    }

    response = Net::HTTP.post_form(uri, params)
    result = JSON.parse(response.body)

    if result["error_code"]
      Rails.logger.error "[BaiduTranslate] API error: #{result['error_code']} - #{result['error_msg']}"
      return nil
    end

    result["trans_result"]&.map { |r| r["dst"] }&.join(" ")
  rescue StandardError => e
    Rails.logger.error "[BaiduTranslate] Service error: #{e.message}"
    nil
  end
end
