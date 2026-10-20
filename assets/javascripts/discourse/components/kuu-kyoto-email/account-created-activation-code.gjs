import Component from "@glimmer/component";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import { isKyotoEmail } from "../../lib/kyoto-email";
import ActivationCodeForm from "./activation-code-form";

// 注册后的等待页（account-created）没有插件挂载点，挂在页面顶部的 above-main-container
export default class AccountCreatedActivationCode extends Component {
  @service router;
  @service site;
  @service siteSettings;

  get accountCreated() {
    return getOwner(this).lookup("controller:account-created")?.accountCreated;
  }

  get visible() {
    return (
      this.siteSettings.kuu_kyoto_email_activation_code_enabled &&
      this.router.currentRouteName?.startsWith("account-created") &&
      this.router.currentRouteName !== "account-created.edit-email" &&
      !!this.accountCreated?.username &&
      isKyotoEmail(this.accountCreated.email, this.site.kuu_kyoto_email_domains)
    );
  }

  <template>
    {{#if this.visible}}
      <div class="kuu-kyoto-email-account-created">
        <ActivationCodeForm
          @email={{this.accountCreated.email}}
          @login={{this.accountCreated.username}}
        />
      </div>
    {{/if}}
  </template>
}
