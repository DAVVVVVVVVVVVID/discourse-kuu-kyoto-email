import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import ActivationControls from "discourse/components/activation-controls";
import ActivationEdit from "discourse/components/modal/activation-edit";
import { ajax } from "discourse/lib/ajax";
import { resendActivationEmail } from "discourse/lib/user-activation";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import ActivationCodeForm from "../activation-code-form";

// 替换 core 的「账号未激活」弹窗：原来的说明和按钮都保留，多一个激活码输入框
export default class NotActivated extends Component {
  @service modal;

  @tracked hasValidCode = true;
  @tracked resent = false;

  constructor() {
    super(...arguments);
    this.#loadCodeStatus();
  }

  get showNoCodeHint() {
    return !this.hasValidCode && !this.resent;
  }

  @action
  async sendActivationEmail() {
    await resendActivationEmail(this.args.model.currentEmail);
    this.resent = true;
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
        {{#if this.resent}}
          <p class="kuu-kyoto-email-not-activated-modal__resent">
            {{i18n "kuu_kyoto_email.activation_code.resent"}}
          </p>
        {{/if}}
        <ActivationCodeForm @login={{@model.username}} />
      </:body>
      <:footer>
        <ActivationControls
          @editActivationEmail={{this.editActivationEmail}}
          @sendActivationEmail={{this.sendActivationEmail}}
        />
      </:footer>
    </DModal>
  </template>
}
