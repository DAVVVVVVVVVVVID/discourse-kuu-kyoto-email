# frozen_string_literal: true

DiscourseKuuKyotoEmail::Engine.routes.draw do
  post "/prompt/dismiss" => "reminders#dismiss_prompt"
  post "/banner/snooze" => "reminders#snooze_banner"
end

Discourse::Application.routes.draw { mount ::DiscourseKuuKyotoEmail::Engine, at: "kuu-kyoto-email" }
