import Component from "@glimmer/component";
import { service } from "@ember/service";
import moment from "moment";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { bindEmailUrl, viewingOwnUserPage } from "../../lib/kyoto-email";

export default class PreferencesKyotoEmail extends Component {
  @service currentUser;
  @service router;

  get bindEmailUrl() {
    return bindEmailUrl(this.currentUser);
  }

  get status() {
    return this.currentUser?.kuu_kyoto_email_status;
  }

  get verifiedOn() {
    const verifiedAt = this.status?.verified_at;
    return verifiedAt
      ? moment(verifiedAt).format(i18n("dates.long_with_year_no_time"))
      : null;
  }

  get visible() {
    return !!this.status && viewingOwnUserPage(this.router, this.currentUser);
  }

  <template>
    {{#if this.visible}}
      <div class="control-group kuu-kyoto-email-section">
        <label class="control-label">
          {{i18n "kuu_kyoto_email.preferences.title"}}
        </label>
        <div class="controls">
          <div class="kuu-kyoto-email-section__email">
            {{dIcon "lock"}}
            <span class="kuu-kyoto-email-section__address">
              {{this.status.kyoto_email}}
            </span>
            {{#if this.verifiedOn}}
              <span class="kuu-kyoto-email-section__verified-on">
                {{i18n
                  "kuu_kyoto_email.preferences.verified_on"
                  date=this.verifiedOn
                }}
              </span>
            {{/if}}
          </div>
          <p class="kuu-kyoto-email-section__description">
            {{i18n "kuu_kyoto_email.preferences.description"}}
          </p>

          {{#if this.status.pending_email}}
            <p class="kuu-kyoto-email-section__pending">
              {{i18n "kuu_kyoto_email.pending" email=this.status.pending_email}}
            </p>
          {{else if this.status.primary_is_kyoto}}
            <div class="kuu-kyoto-email-section__warning">
              {{dIcon "triangle-exclamation"}}
              <span>{{i18n
                  "kuu_kyoto_email.preferences.primary_warning"
                }}</span>
              <a
                class="btn btn-primary btn-small kuu-kyoto-email-section__bind"
                href={{this.bindEmailUrl}}
              >
                {{i18n "kuu_kyoto_email.bind_email"}}
              </a>
            </div>
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
