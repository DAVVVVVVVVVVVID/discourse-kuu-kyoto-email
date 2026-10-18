import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class SignupHint extends Component {
  @service site;

  get visible() {
    // 验证码流程的这个 outlet 登录时也渲染；老注册表单的 outlet 不带 context
    const context = this.args.outletArgs?.context;
    return !!this.domains && (!context || context === "signup");
  }

  get domains() {
    return this.site.kuu_kyoto_email_domains
      ?.map((domain) => `@${domain}`)
      .join(" / ");
  }

  <template>
    {{#if this.visible}}
      <p class="kuu-kyoto-email-signup-hint">
        {{i18n "kuu_kyoto_email.signup_hint" domains=this.domains}}
      </p>
    {{/if}}
  </template>
}
