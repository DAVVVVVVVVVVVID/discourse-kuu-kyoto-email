import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import ActivationEdit from "discourse/components/modal/activation-edit";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import ActivationCodeForm from "../activation-code-form";

// 替换 core 的「账号未激活」弹窗：多一个激活码输入框，「重新发送」挪到「激活」旁边
export default class NotActivated extends Component {
  @service modal;
  @service siteSettings;

  @tracked hasValidCode = true;
  @tracked resent = false;

  constructor() {
    super(...arguments);
    this.#loadCodeStatus();
  }

  get canEditEmail() {
    return (
      this.siteSettings.enable_local_logins || this.siteSettings.email_editable
    );
  }

  get showNoCodeHint() {
    return !this.hasValidCode && !this.resent;
  }

  @action
  editActivationEmail() {
    this.modal.show(ActivationEdit, {
      model: {
        currentEmail: this.args.model.currentEmail,
        newEmail: this.args.model.currentEmail,
      },
    });
  }

  @action
  handleResent() {
    this.resent = true;
  }

  async #loadCodeStatus() {
    try {
      const result = await ajax("/kuu-kyoto-email/activation-code/status");
      this.hasValidCode = result.has_valid_code;
    } catch {
      // 查不到就当作有码，不打扰用户
    }
  }

  <template>
    <DModal
      class="not-activated-modal kuu-kyoto-email-not-activated-modal"
      @closeModal={{@closeModal}}
      @title={{i18n "log_in"}}
    >
      <:body>
        <p>{{trustHTML (i18n "login.not_activated" sentTo=@model.sentTo)}}</p>
        {{#if this.showNoCodeHint}}
          <p class="kuu-kyoto-email-not-activated-modal__no-code">
            {{i18n "kuu_kyoto_email.activation_code.no_valid_code"}}
          </p>
        {{/if}}
        {{! 用户隔了一段时间才回来，码多半已经过期，这里的「重新发送」一开始就能点 }}
        <ActivationCodeForm
          @login={{@model.username}}
          @onResent={{this.handleResent}}
          @resendDelay={{0}}
        />
      </:body>
      <:footer>
        {{#if this.canEditEmail}}
          <DButton
            class="btn-default edit-email"
            @action={{this.editActivationEmail}}
            @icon="pencil"
            @label="login.change_email"
          />
        {{/if}}
      </:footer>
    </DModal>
  </template>
}
