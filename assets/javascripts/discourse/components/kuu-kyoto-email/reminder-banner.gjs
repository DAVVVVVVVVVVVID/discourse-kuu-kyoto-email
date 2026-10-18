import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { bindEmailUrl } from "../../lib/kyoto-email";
import BindEmail from "./modal/bind-email";

// 提示条每次换页都会重新渲染，弹窗一次页面加载只弹一回
let promptOpened = false;

export default class ReminderBanner extends Component {
  @service currentUser;
  @service modal;

  @tracked snoozedUntil = this.status?.banner_snoozed_until;

  constructor() {
    super(...arguments);

    if (this.status?.needs_personal_email && !this.status.prompt_dismissed) {
      if (!promptOpened) {
        promptOpened = true;
        next(() => this.modal.show(BindEmail));
      }
    }
  }

  get bindEmailUrl() {
    return bindEmailUrl(this.currentUser);
  }

  get status() {
    return this.currentUser?.kuu_kyoto_email_status;
  }

  get visible() {
    if (!this.status?.needs_personal_email) {
      return false;
    }

    return !this.snoozedUntil || new Date(this.snoozedUntil) <= new Date();
  }

  @action
  async snooze() {
    try {
      const result = await ajax("/kuu-kyoto-email/banner/snooze", {
        type: "POST",
      });
      this.status.banner_snoozed_until = result.banner_snoozed_until;
      this.snoozedUntil = result.banner_snoozed_until;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    {{#if this.visible}}
      <div class="kuu-kyoto-email-banner">
        {{dIcon "envelope" class="kuu-kyoto-email-banner__icon"}}
        <div class="kuu-kyoto-email-banner__text">
          {{#if this.status.pending_email}}
            {{i18n "kuu_kyoto_email.pending" email=this.status.pending_email}}
          {{else}}
            {{i18n "kuu_kyoto_email.banner.text"}}
            <a class="kuu-kyoto-email-banner__link" href={{this.bindEmailUrl}}>
              {{i18n "kuu_kyoto_email.bind_email"}}
            </a>
          {{/if}}
        </div>
        <DButton
          class="btn-flat kuu-kyoto-email-banner__close"
          @action={{this.snooze}}
          @icon="xmark"
          @title="kuu_kyoto_email.banner.snooze"
        />
      </div>
    {{/if}}
  </template>
}
