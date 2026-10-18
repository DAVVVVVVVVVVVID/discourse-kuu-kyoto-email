import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { bindEmailUrl, viewingOwnUserPage } from "../../lib/kyoto-email";

export default class PreferencesEmailNote extends Component {
  @service currentUser;
  @service router;

  get bindEmailUrl() {
    return bindEmailUrl(this.currentUser);
  }

  get status() {
    return this.currentUser?.kuu_kyoto_email_status;
  }

  get visible() {
    return !!this.status && viewingOwnUserPage(this.router, this.currentUser);
  }

  <template>
    {{#if this.visible}}
      <div class="control-group kuu-kyoto-email-note">
        <p class="kuu-kyoto-email-note__kyoto">
          {{i18n "kuu_kyoto_email.preferences.kyoto_email"}}
        </p>
        {{#if this.status.needs_personal_email}}
          {{#if this.status.pending_email}}
            <p class="kuu-kyoto-email-note__pending">
              {{i18n "kuu_kyoto_email.pending" email=this.status.pending_email}}
            </p>
          {{else}}
            <p>{{i18n "kuu_kyoto_email.preferences.no_personal_email"}}</p>
            <a
              class="btn btn-primary kuu-kyoto-email-note__bind"
              href={{this.bindEmailUrl}}
            >
              {{i18n "kuu_kyoto_email.bind_email"}}
            </a>
          {{/if}}
        {{else}}
          <p class="kuu-kyoto-email-note__personal">
            {{i18n
              "kuu_kyoto_email.preferences.personal_email"
              email=@outletArgs.email
            }}
          </p>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
