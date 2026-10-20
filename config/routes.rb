# frozen_string_literal: true

DiscourseKuuKyotoEmail::Engine.routes.draw do
  post "/prompt/dismiss" => "reminders#dismiss_prompt"
  post "/banner/snooze" => "reminders#snooze_banner"
  post "/activation-code" => "activation_codes#create"
  get "/activation-code/status" => "activation_codes#status"
end

Discourse::Application.routes.draw { mount ::DiscourseKuuKyotoEmail::Engine, at: "kuu-kyoto-email" }
