encryption_config = Rails.application.config.active_record.encryption

if encryption_config.primary_key.blank?
  key_generator = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base, iterations: 1_000)

  encryption_config.primary_key = key_generator.generate_key("active_record_encryption.primary_key", 32).unpack1("H*")
  encryption_config.deterministic_key = key_generator.generate_key("active_record_encryption.deterministic_key", 32).unpack1("H*")
  encryption_config.key_derivation_salt = key_generator.generate_key("active_record_encryption.key_derivation_salt", 32).unpack1("H*")
end
