import Component from "@glimmer/component";
import { get } from "@ember/object";
import { service } from "@ember/service";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";
import { isKyotoEmail } from "../../lib/kyoto-email";

export default class AdminUserKyotoEmail extends Component {
  @service site;

  get info() {
    return this.args.outletArgs.user.kuu_kyoto_email;
  }

  // 只在管理员点了 core 的「显示邮箱」之后才有值，查看邮箱照常记进员工操作日志
  get kyotoEmail() {
    const user = this.args.outletArgs.user;
    const emails = [
      get(user, "email"),
      ...(get(user, "secondary_emails") || []),
    ];
    return emails.find((email) =>
      isKyotoEmail(email, this.site.kuu_kyoto_email_domains)
    );
  }

  <template>
    {{#if this.info}}
      <div class="display-row kuu-kyoto-email-admin">
        <div class="field">{{i18n "kuu_kyoto_email.admin.kyoto_email"}}</div>
        <div class="value">
          <span class="kuu-kyoto-email-admin__email">
            {{#if this.kyotoEmail}}
              {{this.kyotoEmail}}
            {{else}}
              {{i18n "kuu_kyoto_email.admin.reveal_hint"}}
            {{/if}}
          </span>
          {{#if this.info.verified_at}}
            <span class="kuu-kyoto-email-admin__verified-at">
              {{i18n "kuu_kyoto_email.admin.verified_at"}}
              {{dFormatDate this.info.verified_at format="medium"}}
            </span>
          {{/if}}
        </div>
      </div>
      <div class="display-row kuu-kyoto-email-admin-personal">
        <div class="field">{{i18n "kuu_kyoto_email.admin.personal_email"}}</div>
        <div class="value">
          {{#if this.info.has_personal_email}}
            {{i18n "kuu_kyoto_email.admin.personal_email_bound"}}
          {{else}}
            {{i18n "kuu_kyoto_email.admin.personal_email_missing"}}
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
