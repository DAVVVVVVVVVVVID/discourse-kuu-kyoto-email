import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseURL from "discourse/lib/url";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import { bindEmailUrl } from "../../../lib/kyoto-email";

export default class BindEmail extends Component {
  @service currentUser;

  @action
  bindNow() {
    this.close();
    DiscourseURL.routeTo(bindEmailUrl(this.currentUser));
  }

  @action
  close() {
    this.currentUser.kuu_kyoto_email_status.prompt_dismissed = true;
    ajax("/kuu-kyoto-email/prompt/dismiss", { type: "POST" }).catch(() => {});
    this.args.closeModal();
  }

  <template>
    <DModal
      class="kuu-kyoto-email-bind-modal"
      @closeModal={{this.close}}
      @title={{i18n "kuu_kyoto_email.bind_modal.title"}}
    >
      <:body>
        <p>{{i18n "kuu_kyoto_email.bind_modal.why"}}</p>
        <p>{{i18n "kuu_kyoto_email.bind_modal.how"}}</p>
      </:body>
      <:footer>
        <DButton
          class="btn-primary kuu-kyoto-email-bind-modal__bind"
          @action={{this.bindNow}}
          @label="kuu_kyoto_email.bind_email"
        />
        <DButton
          class="btn-flat kuu-kyoto-email-bind-modal__later"
          @action={{this.close}}
          @label="kuu_kyoto_email.bind_modal.later"
        />
      </:footer>
    </DModal>
  </template>
}
