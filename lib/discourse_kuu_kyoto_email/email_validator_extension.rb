# frozen_string_literal: true

module DiscourseKuuKyotoEmail
  module EmailValidatorExtension
    def allowed?(email)
      super || EmailPolicy.allows?(email)
    end
  end
end
