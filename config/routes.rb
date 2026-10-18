# frozen_string_literal: true

DiscourseKuuKyotoEmail::Engine.routes.draw {}

Discourse::Application.routes.draw { mount ::DiscourseKuuKyotoEmail::Engine, at: "kuu-kyoto-email" }
