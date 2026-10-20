import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import ActivationControls from "discourse/components/activation-controls";
import ActivationEdit from "discourse/components/modal/activation-edit";
import { resendActivationEmail } from "discourse/lib/user-activation";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import ActivationCodeForm from "../activation-code-form";

// 替换 core 的「账号未激活」弹窗：原来的说明和按钮都保留，多一个激活码输入框
export default class NotActivated extends Component {
  @service modal;

  @tracked resent = false;

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

  <template>
    <DModal
      class="not-activated-modal kuu-kyoto-email-not-activated-modal"
      @closeModal={{@closeModal}}
      @title={{i18n "log_in"}}
    >
      <:body>
        <p>{{trustHTML (i18n "login.not_activated" sentTo=@model.sentTo)}}</p>
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
