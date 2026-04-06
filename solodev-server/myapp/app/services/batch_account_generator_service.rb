class BatchAccountGeneratorService
  attr_reader :count, :email_domain, :password, :role, :results

  def initialize(count:, email_domain:, password:, role: "user")
    @count = count.to_i
    @email_domain = email_domain.to_s.strip
    @password = password.to_s.strip
    @role = role.to_s.strip
    @results = []
  end

  def call
    return { success: false, message: "数量需在 1~100 之间", results: [] } unless count.between?(1, 100)
    return { success: false, message: "邮箱域名不能为空", results: [] } if email_domain.blank?
    return { success: false, message: "密码不能为空，且至少 6 个字符", results: [] } if password.length < 6
    return { success: false, message: "角色无效", results: [] } unless User.roles.key?(role)

    generated = 0
    generated_usernames = User.pluck(:username).index_with(&:itself)

    count.times do
      username = generate_unique_username(generated_usernames)
      email = "#{username}@#{email_domain}"

      user = User.new(
        username: username,
        email: email,
        password: password,
        password_confirmation: password,
        role: role,
        is_operational: true,
        plaintext_password: password
      )

      if user.save
        generated_usernames[username] = true
        generated += 1
        results << { username: username, email: email, password: password, success: true }
      else
        results << { username: username, email: email, password: password, success: false, errors: user.errors.full_messages.join(", ") }
      end
    end

    { success: true, message: "成功生成 #{generated}/#{count} 个账号", results: results }
  end

  private

  def generate_unique_username(existing)
    20.times do
      username = Faker::Internet.username(specifier: 6..10, separators: ["_"])
      username = username.gsub(/[^a-zA-Z0-9_]/, "")[0, 20]

      next if username.length < 2
      next if existing.key?(username.downcase)

      return username
    end

    # Fallback: random alphanumeric
    SecureRandom.alphanumeric(8).downcase
  end
end
