import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { cancel } from "@ember/runloop";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseLater from "discourse/lib/later";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

const RESEND_INTERVAL_SECONDS = 60;

// 倒计时期间灰色不能点，到时间才能重新发送；点了以后再倒计时一轮
export default class ResendActivationButton extends Component {
  @tracked secondsLeft = this.args.initialDelay ?? RESEND_INTERVAL_SECONDS;
  @tracked sending = false;

  #timer;

  constructor() {
    super(...arguments);
    this.#tick();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    cancel(this.#timer);
  }

  get disabled() {
    return this.sending || this.secondsLeft > 0;
  }

  get label() {
    return this.secondsLeft > 0
      ? i18n("kuu_kyoto_email.activation_code.resend_countdown", {
          count: this.secondsLeft,
        })
      : i18n("kuu_kyoto_email.activation_code.resend");
  }

  @action
  async resend() {
    this.sending = true;

    try {
      await ajax("/kuu-kyoto-email/activation-code/resend", { type: "POST" });
      this.secondsLeft = RESEND_INTERVAL_SECONDS;
      this.#tick();
      this.args.onResent?.();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.sending = false;
    }
  }

  #tick() {
    cancel(this.#timer);
    if (this.secondsLeft <= 0) {
      return;
    }

    this.#timer = discourseLater(() => {
      this.secondsLeft -= 1;
      this.#tick();
    }, 1000);
  }

  <template>
    <DButton
      class="btn-default kuu-kyoto-email-activation-code__resend"
      @action={{this.resend}}
      @disabled={{this.disabled}}
      @translatedLabel={{this.label}}
    />
  </template>
}
